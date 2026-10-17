import CoreGraphics
import simd

/// Pan and zoom over the graph, in world coordinates.
///
/// The camera is deliberately a plain value type: the renderer reads it every frame and
/// gesture handlers write it, so keeping it free of behaviour makes that traffic easy to
/// reason about.
public struct GraphCamera: Sendable, Equatable {
    /// World point displayed at the centre of the view.
    public var center: SIMD2<Float> = .zero
    /// Pixels per world unit.
    public var scale: Float = 1

    public static let minimumScale: Float = 0.02
    public static let maximumScale: Float = 12

    public init(center: SIMD2<Float> = .zero, scale: Float = 1) {
        self.center = center
        self.scale = scale
    }

    public mutating func clampScale() {
        scale = min(Self.maximumScale, max(Self.minimumScale, scale))
    }

    /// Zooms about a fixed point so the world position under the cursor stays put.
    ///
    /// - Parameters:
    ///   - factor: Multiplier applied to ``scale``.
    ///   - anchor: The pixel to hold steady, relative to the view centre.
    public mutating func zoom(by factor: Float, around anchor: SIMD2<Float>) {
        let before = worldPoint(fromCenterOffset: anchor)
        scale *= factor
        clampScale()
        let after = worldPoint(fromCenterOffset: anchor)
        center += before - after
    }

    /// Converts a pixel offset from the view centre into a world position.
    public func worldPoint(fromCenterOffset offset: SIMD2<Float>) -> SIMD2<Float> {
        center + offset / max(scale, .leastNormalMagnitude)
    }

    /// Converts a world position into a pixel offset from the view centre.
    public func centerOffset(forWorldPoint point: SIMD2<Float>) -> SIMD2<Float> {
        (point - center) * scale
    }

    /// Frames `bounds` in a viewport of `viewportSize` pixels with a little margin.
    public mutating func fit(
        bounds: (min: SIMD2<Float>, max: SIMD2<Float>),
        viewportSize: SIMD2<Float>,
        padding: Float = 48
    ) {
        guard viewportSize.x > 0, viewportSize.y > 0 else { return }
        let extent = bounds.max - bounds.min
        center = (bounds.min + bounds.max) * 0.5

        let usable = SIMD2<Float>(
            max(viewportSize.x - padding * 2, 1),
            max(viewportSize.y - padding * 2, 1)
        )
        // A single node, or a perfectly collinear graph, has zero extent on some axis.
        let width = max(extent.x, 1)
        let height = max(extent.y, 1)
        scale = min(usable.x / width, usable.y / height)
        clampScale()
    }
}
