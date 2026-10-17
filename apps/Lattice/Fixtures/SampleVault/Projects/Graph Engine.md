---
tags: [project, area/tools, tech/metal]
---

# Graph Engine

Force-directed layout in Metal compute shaders.

Repulsion is exact all-pairs, tiled through threadgroup memory. Attraction walks CSR
adjacency so it needs no atomics. See [[Lattice]]. ^kernels

Nothing here depends on the note store — the engine takes a snapshot and nothing else.
