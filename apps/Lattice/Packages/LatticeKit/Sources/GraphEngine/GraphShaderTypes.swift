import simd

// Swift mirrors of the structs in `Shaders/GraphShaders.metal`.
//
// SwiftPM gives a Metal file no dependable way to include a header from a Swift target,
// so these definitions are duplicated rather than shared. They must stay byte-identical;
// `GraphShaderTypes.validateLayout()` checks the sizes at startup in debug builds so a
// mismatch surfaces as a clear assertion instead of a garbled simulation.

struct NodeFlags: OptionSet {
    let rawValue: UInt32
    static let pinned = NodeFlags(rawValue: 1 << 0)
    static let placeholder = NodeFlags(rawValue: 1 << 1)
}

struct NodeMeta {
    var mass: Float
    var radius: Float
    var group: UInt32
    var flags: UInt32
}

struct LayoutUniforms {
    var nodeCount: UInt32 = 0
    var deltaTime: Float = 1.0 / 60.0
    var repulsion: Float = 0
    var springStrength: Float = 0
    var idealLength: Float = 0
    var damping: Float = 0
    var gravity: Float = 0
    var maxSpeed: Float = 0
    var softening: Float = 0
    var temperature: Float = 1
    var pad0: UInt32 = 0
    var pad1: UInt32 = 0
}

struct GraphStats {
    var minBound: SIMD2<Float> = .init(repeating: .greatestFiniteMagnitude)
    var maxBound: SIMD2<Float> = .init(repeating: -.greatestFiniteMagnitude)
    var energy: Float = 0
    var pad0: Float = 0
}

struct RenderUniforms {
    var viewportSize: SIMD2<Float> = .zero
    var cameraCenter: SIMD2<Float> = .zero
    var cameraScale: Float = 1
    var nodeScale: Float = 1
    var edgeWidth: Float = 1
    var time: Float = 0
    var edgeColor: SIMD4<Float> = .init(1, 1, 1, 0.25)
    var selectionColor: SIMD4<Float> = .init(1, 1, 1, 1)
    var highlightIndex: UInt32 = .max
    var selectedIndex: UInt32 = .max
    var dimAmount: Float = 0.75
    var pad0: Float = 0
}

enum GraphShaderTypes {
    /// Sentinel matching `NoIndex` in the shader.
    static let noIndex = UInt32.max

    /// Sizes the Metal compiler produces for the mirrored structs.
    ///
    /// Every field is a scalar or a SIMD vector, so both compilers apply the same C
    /// alignment rules; these constants pin that assumption down.
    static func validateLayout() {
        assert(MemoryLayout<NodeMeta>.stride == 16, "NodeMeta layout drifted from the shader")
        assert(MemoryLayout<LayoutUniforms>.stride == 48, "LayoutUniforms layout drifted")
        assert(MemoryLayout<GraphStats>.stride == 24, "GraphStats layout drifted")
        assert(MemoryLayout<RenderUniforms>.stride == 80, "RenderUniforms layout drifted")
    }
}
