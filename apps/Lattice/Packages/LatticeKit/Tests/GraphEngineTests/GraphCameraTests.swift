import Testing
import simd
@testable import GraphEngine

@Suite("GraphCamera")
struct GraphCameraTests {
    @Test("Round-trips between world space and pixel offsets")
    func roundTrip() {
        var camera = GraphCamera(center: SIMD2(10, -20), scale: 2.5)
        let world = SIMD2<Float>(42, 17)
        let offset = camera.centerOffset(forWorldPoint: world)
        let back = camera.worldPoint(fromCenterOffset: offset)
        #expect(abs(back.x - world.x) < 0.001)
        #expect(abs(back.y - world.y) < 0.001)
        camera.clampScale()
        #expect(camera.scale == 2.5)
    }

    @Test("Zooming holds the world point under the anchor steady")
    func zoomAroundAnchor() {
        var camera = GraphCamera(center: .zero, scale: 1)
        let anchor = SIMD2<Float>(120, -60)
        let before = camera.worldPoint(fromCenterOffset: anchor)
        camera.zoom(by: 2.5, around: anchor)
        let after = camera.worldPoint(fromCenterOffset: anchor)
        // This is the whole point of anchored zoom: the pixel under the cursor keeps
        // showing the same part of the graph.
        #expect(abs(after.x - before.x) < 0.01)
        #expect(abs(after.y - before.y) < 0.01)
        #expect(camera.scale == 2.5)
    }

    @Test("Scale stays inside its limits however hard it is pushed")
    func clampsScale() {
        var camera = GraphCamera(center: .zero, scale: 1)
        camera.zoom(by: 10_000, around: .zero)
        #expect(camera.scale == GraphCamera.maximumScale)
        camera.zoom(by: 0.000_001, around: .zero)
        #expect(camera.scale == GraphCamera.minimumScale)
    }

    @Test("Fitting centres the bounds and leaves a margin")
    func fitCentresBounds() {
        var camera = GraphCamera()
        camera.fit(
            bounds: (min: SIMD2(-100, -50), max: SIMD2(100, 50)),
            viewportSize: SIMD2(1000, 600),
            padding: 50
        )
        #expect(camera.center == SIMD2<Float>(0, 0))
        // 200 wide into 900 usable, 100 tall into 500 usable: height is the binding axis.
        #expect(abs(camera.scale - 4.5) < 0.001)
    }

    @Test("Fitting a single node does not divide by zero")
    func fitDegenerateBounds() {
        var camera = GraphCamera()
        camera.fit(
            bounds: (min: SIMD2(5, 5), max: SIMD2(5, 5)),
            viewportSize: SIMD2(800, 600)
        )
        #expect(camera.center == SIMD2<Float>(5, 5))
        #expect(camera.scale.isFinite)
        #expect(camera.scale <= GraphCamera.maximumScale)
    }

    @Test("Fitting into a zero-sized viewport is ignored rather than producing NaN")
    func fitEmptyViewport() {
        var camera = GraphCamera(center: SIMD2(1, 2), scale: 3)
        camera.fit(bounds: (min: .zero, max: SIMD2(10, 10)), viewportSize: .zero)
        #expect(camera.center == SIMD2<Float>(1, 2))
        #expect(camera.scale == 3)
    }
}
