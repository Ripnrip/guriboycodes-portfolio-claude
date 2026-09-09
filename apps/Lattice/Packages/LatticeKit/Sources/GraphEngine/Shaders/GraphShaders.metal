#include <metal_stdlib>
using namespace metal;

// MARK: - Shared layout
//
// These structs are mirrored in Swift by `GraphShaderTypes.swift`. SwiftPM gives a Metal
// target no reliable way to include a header from a Swift target, so the definitions are
// duplicated rather than shared. `GraphShaderTypes` asserts the Swift sizes at startup in
// debug builds; if you change a field here, change it there too.

constant uint NodeFlagPinned      = 1u << 0;
constant uint NodeFlagPlaceholder = 1u << 1;

struct NodeMeta {
    float mass;
    float radius;
    uint  group;
    uint  flags;
};

struct LayoutUniforms {
    uint  nodeCount;
    float deltaTime;
    float repulsion;
    float springStrength;
    float idealLength;
    float damping;
    float gravity;
    float maxSpeed;
    float softening;
    float temperature;
    uint  pad0;
    uint  pad1;
};

struct GraphStats {
    float2 minBound;
    float2 maxBound;
    float  energy;
    float  pad0;
};

struct RenderUniforms {
    float2 viewportSize;   // drawable size in pixels
    float2 cameraCenter;   // world point at the centre of the view
    float  cameraScale;    // pixels per world unit
    float  nodeScale;
    float  edgeWidth;      // pixels
    float  time;
    float4 edgeColor;
    float4 selectionColor;
    uint   highlightIndex; // node under the cursor, or 0xFFFFFFFF
    uint   selectedIndex;  // node the user opened, or 0xFFFFFFFF
    float  dimAmount;      // how far to fade nodes outside the highlight
    float  pad0;
};

constant uint NoIndex = 0xFFFFFFFFu;

// MARK: - Layout kernels

/// Repulsion between every pair of nodes, tiled through threadgroup memory.
///
/// Each threadgroup stages a block of positions into `tile` so that all of its threads
/// read the same values from fast memory rather than each thread walking device memory
/// on its own. That is what makes the exact O(N^2) formulation fast enough to prefer over
/// a Barnes-Hut approximation at the graph sizes a personal vault produces.
///
/// The loop bound depends only on `nodeCount` and the threadgroup size, both uniform, so
/// every thread reaches every barrier the same number of times.
kernel void graph_repulsion(
    device const float2     *positions [[buffer(0)]],
    device const NodeMeta   *meta      [[buffer(1)]],
    device float2           *forces    [[buffer(2)]],
    constant LayoutUniforms &u         [[buffer(3)]],
    threadgroup float4      *tile      [[threadgroup(0)]],
    uint gid    [[thread_position_in_grid]],
    uint tid    [[thread_index_in_threadgroup]],
    uint tgSize [[threads_per_threadgroup]])
{
    const uint n = u.nodeCount;
    const uint self = min(gid, n - 1u);
    const float2 pi = positions[self];
    const float charge = meta[self].mass;

    float2 force = float2(0.0);

    for (uint base = 0; base < n; base += tgSize) {
        const uint load = base + tid;
        tile[tid] = (load < n)
            ? float4(positions[load], meta[load].mass, 0.0)
            : float4(0.0);
        threadgroup_barrier(mem_flags::mem_threadgroup);

        const uint count = min(tgSize, n - base);
        for (uint j = 0; j < count; ++j) {
            const float2 delta = pi - tile[j].xy;
            // Softening keeps coincident nodes finite and makes a node's interaction with
            // itself contribute exactly zero, so no self-check is needed in the hot loop.
            const float distSq = dot(delta, delta) + u.softening;
            const float invDist = rsqrt(distSq);
            force += delta * (u.repulsion * tile[j].z * invDist * invDist * invDist);
        }
        threadgroup_barrier(mem_flags::mem_threadgroup);
    }

    if (gid < n) {
        forces[gid] = force * charge;
    }
}

/// Spring attraction along edges, walked through CSR adjacency.
///
/// Each thread owns one node and reads only its own slice, so the accumulation into
/// `forces` needs no atomics. Runs after `graph_repulsion`, adding to what it wrote.
kernel void graph_attraction(
    device const float2     *positions    [[buffer(0)]],
    device float2           *forces       [[buffer(1)]],
    device const uint       *adjOffsets   [[buffer(2)]],
    device const uint       *adjNeighbors [[buffer(3)]],
    device const float      *adjWeights   [[buffer(4)]],
    constant LayoutUniforms &u            [[buffer(5)]],
    uint gid [[thread_position_in_grid]])
{
    if (gid >= u.nodeCount) { return; }

    const float2 pi = positions[gid];
    float2 force = forces[gid];

    const uint start = adjOffsets[gid];
    const uint end   = adjOffsets[gid + 1];
    for (uint k = start; k < end; ++k) {
        const float2 delta = positions[adjNeighbors[k]] - pi;
        const float dist = max(length(delta), 1e-4);
        const float2 direction = delta / dist;
        // Hooke's law about the ideal edge length, weighted by how many times the pair
        // is linked, so a note cited repeatedly sits closer than one cited once.
        force += direction * (dist - u.idealLength) * u.springStrength * adjWeights[k];
    }
    forces[gid] = force;
}

/// Velocity Verlet integration with damping, gravity, annealing, and a speed clamp.
kernel void graph_integrate(
    device float2           *positions  [[buffer(0)]],
    device float2           *velocities [[buffer(1)]],
    device const float2     *forces     [[buffer(2)]],
    device const NodeMeta   *meta       [[buffer(3)]],
    constant LayoutUniforms &u          [[buffer(4)]],
    uint gid [[thread_position_in_grid]])
{
    if (gid >= u.nodeCount) { return; }

    const NodeMeta m = meta[gid];
    if (m.flags & NodeFlagPinned) {
        // A dragged or pinned node is positioned by the user, not by the simulation.
        velocities[gid] = float2(0.0);
        return;
    }

    const float2 p = positions[gid];
    // Gravity toward the origin keeps disconnected components from drifting apart forever.
    const float2 force = forces[gid] - p * u.gravity;
    const float2 accel = force / max(m.mass, 1e-3);

    float2 v = (velocities[gid] + accel * u.deltaTime) * u.damping * u.temperature;
    const float speed = length(v);
    if (speed > u.maxSpeed) {
        v *= u.maxSpeed / speed;
    }

    velocities[gid] = v;
    positions[gid] = p + v * u.deltaTime;
}

/// Per-threadgroup reduction of bounds and kinetic energy.
///
/// The CPU sums the handful of partials to fit the camera and to decide when the layout
/// has settled enough to stop stepping — which is what keeps an idle graph off the GPU.
kernel void graph_reduce(
    device const float2     *positions  [[buffer(0)]],
    device const float2     *velocities [[buffer(1)]],
    device GraphStats       *partials   [[buffer(2)]],
    constant LayoutUniforms &u          [[buffer(3)]],
    threadgroup GraphStats  *scratch    [[threadgroup(0)]],
    uint gid     [[thread_position_in_grid]],
    uint tid     [[thread_index_in_threadgroup]],
    uint tgSize  [[threads_per_threadgroup]],
    uint groupID [[threadgroup_position_in_grid]])
{
    GraphStats local;
    if (gid < u.nodeCount) {
        const float2 p = positions[gid];
        const float2 v = velocities[gid];
        local.minBound = p;
        local.maxBound = p;
        local.energy = dot(v, v);
    } else {
        // Identity element: bounds that lose every min/max, and no energy.
        local.minBound = float2(INFINITY);
        local.maxBound = float2(-INFINITY);
        local.energy = 0.0;
    }
    local.pad0 = 0.0;
    scratch[tid] = local;
    threadgroup_barrier(mem_flags::mem_threadgroup);

    for (uint stride = tgSize / 2; stride > 0; stride >>= 1) {
        if (tid < stride) {
            GraphStats other = scratch[tid + stride];
            scratch[tid].minBound = min(scratch[tid].minBound, other.minBound);
            scratch[tid].maxBound = max(scratch[tid].maxBound, other.maxBound);
            scratch[tid].energy += other.energy;
        }
        threadgroup_barrier(mem_flags::mem_threadgroup);
    }

    if (tid == 0) {
        partials[groupID] = scratch[0];
    }
}

// MARK: - Rendering

static inline float2 worldToPixels(float2 world, constant RenderUniforms &u)
{
    return (world - u.cameraCenter) * u.cameraScale;
}

static inline float4 pixelsToClip(float2 pixels, constant RenderUniforms &u)
{
    const float2 ndc = pixels / (0.5 * u.viewportSize);
    return float4(ndc, 0.0, 1.0);
}

/// A small categorical palette. Placeholder nodes bypass this and draw grey.
constant float3 kNodePalette[8] = {
    float3(0.38, 0.65, 0.98),  // blue
    float3(0.98, 0.62, 0.32),  // orange
    float3(0.45, 0.82, 0.55),  // green
    float3(0.85, 0.48, 0.78),  // magenta
    float3(0.95, 0.80, 0.35),  // yellow
    float3(0.55, 0.55, 0.92),  // indigo
    float3(0.40, 0.80, 0.82),  // teal
    float3(0.92, 0.48, 0.48),  // red
};

static inline float3 paletteColor(uint group)
{
    return kNodePalette[group % 8u];
}

struct EdgeOut {
    float4 position [[position]];
    float4 color;
};

/// Expands each edge into a screen-space quad so line width stays constant in pixels
/// regardless of zoom — which is why this does not use Metal's line primitive.
vertex EdgeOut graph_edge_vertex(
    uint vid [[vertex_id]],
    uint iid [[instance_id]],
    device const float2     *positions [[buffer(0)]],
    device const uint2      *edges     [[buffer(1)]],
    device const float      *weights   [[buffer(2)]],
    constant RenderUniforms &u         [[buffer(3)]])
{
    const uint2 edge = edges[iid];
    const float2 pxA = worldToPixels(positions[edge.x], u);
    const float2 pxB = worldToPixels(positions[edge.y], u);

    const float2 along = pxB - pxA;
    const float lineLength = max(length(along), 1e-6);
    const float2 normal = float2(-along.y, along.x) / lineLength;

    // Two triangles: A+, A-, B+, then B+, A-, B-.
    const uint corners[6] = { 0u, 1u, 2u, 2u, 1u, 3u };
    const uint corner = corners[vid];
    const bool atB = (corner >= 2u);
    const float side = (corner & 1u) ? -1.0 : 1.0;

    const float halfWidth = max(u.edgeWidth, 1.0) * 0.5;
    const float2 pixel = (atB ? pxB : pxA) + normal * side * halfWidth;

    EdgeOut out;
    out.position = pixelsToClip(pixel, u);
    // Heavier edges read as more opaque rather than thicker, which keeps hubs legible.
    const float emphasis = saturate(0.35 + 0.15 * weights[iid]);
    out.color = float4(u.edgeColor.rgb, u.edgeColor.a * emphasis);
    return out;
}

fragment float4 graph_edge_fragment(EdgeOut in [[stage_in]])
{
    return in.color;
}

struct NodeOut {
    float4 position [[position]];
    float2 uv;             // -1..1 across the quad
    float4 fill;
    float4 stroke;
    float  pixelRadius;
    float  strokeWidth;    // in uv units; 0 for a solid node
};

/// One instanced quad per node; the circle itself is drawn analytically in the fragment
/// shader, so it stays perfectly smooth at any zoom without any texture.
vertex NodeOut graph_node_vertex(
    uint vid [[vertex_id]],
    uint iid [[instance_id]],
    device const float2     *positions [[buffer(0)]],
    device const NodeMeta   *meta      [[buffer(1)]],
    constant RenderUniforms &u         [[buffer(2)]])
{
    const NodeMeta m = meta[iid];
    const float2 centre = worldToPixels(positions[iid], u);

    // Keep a floor on drawn size so a zoomed-out graph still reads as nodes, not dust.
    const float pixelRadius = max(m.radius * u.nodeScale * u.cameraScale, 1.5);

    const float2 offsets[6] = {
        float2(-1.0, -1.0), float2(1.0, -1.0), float2(-1.0, 1.0),
        float2(-1.0,  1.0), float2(1.0, -1.0), float2( 1.0, 1.0),
    };
    const float2 uv = offsets[vid];

    NodeOut out;
    out.position = pixelsToClip(centre + uv * pixelRadius, u);
    out.uv = uv;
    out.pixelRadius = pixelRadius;

    const bool isPlaceholder = (m.flags & NodeFlagPlaceholder) != 0;
    const float3 base = isPlaceholder ? float3(0.55) : paletteColor(m.group);

    // Dim everything that is not in the highlighted neighbourhood.
    float emphasis = 1.0;
    if (u.highlightIndex != NoIndex && iid != u.highlightIndex) {
        emphasis = 1.0 - u.dimAmount;
    }

    if (isPlaceholder) {
        // A note that is linked to but not yet written: outline only.
        out.fill = float4(base * 0.25, 0.55 * emphasis);
        out.stroke = float4(base, 0.9 * emphasis);
        out.strokeWidth = 0.22;
    } else {
        out.fill = float4(base, emphasis);
        out.stroke = float4(0.0);
        out.strokeWidth = 0.0;
    }

    if (iid == u.selectedIndex || iid == u.highlightIndex) {
        out.stroke = u.selectionColor;
        out.strokeWidth = 0.20;
    }
    return out;
}

fragment float4 graph_node_fragment(NodeOut in [[stage_in]])
{
    const float distance = length(in.uv);
    // One pixel of feather, expressed in uv units, gives resolution-independent AA.
    const float feather = max(1.0 / in.pixelRadius, 0.01);
    const float alpha = 1.0 - smoothstep(1.0 - feather, 1.0, distance);
    if (alpha <= 0.0) { discard_fragment(); }

    float4 color = in.fill;
    if (in.strokeWidth > 0.0) {
        const float inner = 1.0 - in.strokeWidth;
        const float ring = smoothstep(inner - feather, inner, distance);
        color = mix(in.fill, in.stroke, ring);
    }
    return float4(color.rgb, color.a * alpha);
}
