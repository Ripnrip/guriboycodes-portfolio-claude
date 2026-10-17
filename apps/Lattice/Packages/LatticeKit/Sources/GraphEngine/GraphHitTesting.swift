import Foundation
import simd

extension GraphSimulation {
    /// The node whose disc contains `worldPoint`, or `nil` for empty space.
    ///
    /// A linear scan over the shared position buffer: at the sizes a personal vault
    /// produces this is a few thousand distance comparisons against memory the CPU can
    /// already see, which costs less than building and maintaining a spatial index would.
    /// If vaults ever reach six figures, a uniform grid rebuilt per frame is the upgrade.
    ///
    /// - Parameter tolerance: Extra world-space slack, so small nodes stay tappable.
    public func node(at worldPoint: SIMD2<Float>, tolerance: Float = 0) -> Int? {
        guard let positions, let metaBuffer = renderMeta else { return nil }
        let meta = metaBuffer.contents().bindMemory(to: NodeMeta.self, capacity: positions.count)

        var best: Int?
        var bestDistanceSquared = Float.greatestFiniteMagnitude
        for index in positions.indices {
            let delta = positions[index] - worldPoint
            let distanceSquared = simd_length_squared(delta)
            let reach = meta[index].radius + tolerance
            guard distanceSquared <= reach * reach else { continue }
            if distanceSquared < bestDistanceSquared {
                bestDistanceSquared = distanceSquared
                best = index
            }
        }
        return best
    }

    /// Current world position of a node, for anchoring popovers and labels.
    public func position(ofNodeAt index: Int) -> SIMD2<Float>? {
        guard let positions, index >= 0, index < positions.count else { return nil }
        return positions[index]
    }
}
