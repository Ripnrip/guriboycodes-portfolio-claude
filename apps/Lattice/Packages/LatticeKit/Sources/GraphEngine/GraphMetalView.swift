import MetalKit
import SwiftUI
import simd

#if os(macOS)
import AppKit
public typealias PlatformViewRepresentable = NSViewRepresentable
#else
import UIKit
public typealias PlatformViewRepresentable = UIViewRepresentable
#endif

/// What the graph reports back to the app.
@MainActor
public protocol GraphInteractionDelegate: AnyObject {
    /// The pointer moved over a node, or off every node when `index` is nil.
    func graphDidHover(nodeAt index: Int?)
    /// The user activated a node — a click on macOS, a tap on iOS.
    func graphDidActivate(nodeAt index: Int)
    /// The user dismissed the selection by acting on empty space.
    func graphDidClearSelection()
}

/// The `MTKView` subclass that owns gesture handling.
///
/// Interaction lives here rather than in SwiftUI because pan, zoom, and node dragging all
/// need pixel-accurate coordinates and must not wait on a SwiftUI layout pass — a
/// `DragGesture` over a 120 Hz Metal view is visibly laggier than the platform recogniser.
@MainActor
public final class GraphMetalView: MTKView {
    public weak var interactionDelegate: (any GraphInteractionDelegate)?
    private var renderer: GraphRenderer?
    private var draggingNode: Int?
    private var lastPanLocation: CGPoint?

    /// - Parameter renderer: `nil` when Metal could not be initialised, in which case the
    ///   view is inert and the surrounding SwiftUI shows the failure instead.
    public init(renderer: GraphRenderer?) {
        self.renderer = renderer
        super.init(
            frame: .zero,
            device: renderer?.simulation.device ?? MTLCreateSystemDefaultDevice()
        )
        self.delegate = renderer
        renderer?.attachedView = self
        if renderer == nil { isPaused = true }
        commonSetup()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("GraphMetalView is created in code, not from a nib")
    }

    private func commonSetup() {
        colorPixelFormat = .bgra8Unorm
        sampleCount = GraphMetalView.preferredSampleCount
        // Nothing is layered in depth, so the pass needs no depth attachment at all.
        depthStencilPixelFormat = .invalid
        isOpaque = true
        preferredFramesPerSecond = 60  // raised to the display's rate once in a window
        installGestureRecognizers()
    }

    /// 4× MSAA is close to free on Apple's tile-based GPUs and is what keeps thin edges
    /// from crawling; the node circles are already analytically antialiased.
    static let preferredSampleCount = 4

    /// Matches the display so ProMotion panels actually run the layout at 120 Hz.
    ///
    /// Re-read when the view changes window, because the right answer differs between an
    /// internal 120 Hz panel and an external 60 Hz one.
    private var displayRefreshRate: Int {
        #if os(macOS)
        return (window?.screen ?? NSScreen.main).map { Int($0.maximumFramesPerSecond) } ?? 60
        #else
        return window?.screen.maximumFramesPerSecond ?? 60
        #endif
    }

    #if os(macOS)
    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        preferredFramesPerSecond = displayRefreshRate
    }
    #else
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        preferredFramesPerSecond = displayRefreshRate
    }
    #endif

    // MARK: - Coordinate conversion

    /// Converts a point in view coordinates into the graph's world space.
    private func worldPoint(from viewPoint: CGPoint) -> SIMD2<Float> {
        guard let renderer else { return .zero }
        let scale = drawableScaleFactor
        // The shader measures from the centre of the drawable, with y increasing upward.
        let centred = SIMD2<Float>(
            Float(viewPoint.x * scale) - renderer.currentViewportSize.x / 2,
            renderer.currentViewportSize.y / 2 - Float(viewPoint.y * scale)
        )
        return renderer.camera.worldPoint(fromCenterOffset: centred)
    }

    private var drawableScaleFactor: CGFloat {
        #if os(macOS)
        return window?.backingScaleFactor ?? 2
        #else
        return window?.screen.scale ?? UIScreen.main.scale
        #endif
    }

    /// World-space slack so a small node is still easy to hit with a finger.
    private var hitTolerance: Float {
        guard let renderer else { return 0 }
        #if os(macOS)
        let pointSlack: Float = 4
        #else
        let pointSlack: Float = 14
        #endif
        return pointSlack / max(renderer.camera.scale, 0.0001)
    }

    // MARK: - Shared interaction

    private func beginDrag(at viewPoint: CGPoint) {
        guard let renderer else { return }
        let world = worldPoint(from: viewPoint)
        lastPanLocation = viewPoint
        if let index = renderer.simulation.node(at: world, tolerance: hitTolerance) {
            draggingNode = index
            renderer.simulation.setPosition(world, forNodeAt: index, pinned: true)
            renderer.resume()
        } else {
            draggingNode = nil
        }
    }

    private func continueDrag(to viewPoint: CGPoint) {
        guard let renderer else { return }
        defer { lastPanLocation = viewPoint }

        if let index = draggingNode {
            renderer.simulation.setPosition(worldPoint(from: viewPoint), forNodeAt: index, pinned: true)
            renderer.resume()
            return
        }

        // No node under the cursor, so the gesture pans the camera instead.
        guard let previous = lastPanLocation else { return }
        let scale = drawableScaleFactor
        let deltaPixels = SIMD2<Float>(
            Float((viewPoint.x - previous.x) * scale),
            Float((previous.y - viewPoint.y) * scale)
        )
        renderer.camera.center -= deltaPixels / max(renderer.camera.scale, 0.0001)
        renderer.setNeedsRedraw()
    }

    private func endDrag(at viewPoint: CGPoint, wasClick: Bool) {
        guard let renderer else { return }
        if let index = draggingNode {
            // Release the pin so the layout reclaims the node.
            renderer.simulation.setPosition(
                worldPoint(from: viewPoint),
                forNodeAt: index,
                pinned: false
            )
            renderer.resume()
            if wasClick {
                renderer.selectedNode = index
                interactionDelegate?.graphDidActivate(nodeAt: index)
            }
        } else if wasClick {
            renderer.selectedNode = nil
            interactionDelegate?.graphDidClearSelection()
            renderer.setNeedsRedraw()
        }
        draggingNode = nil
        lastPanLocation = nil
    }

    private func zoom(by factor: CGFloat, at viewPoint: CGPoint) {
        guard let renderer, factor.isFinite, factor > 0 else { return }
        let scale = drawableScaleFactor
        let anchor = SIMD2<Float>(
            Float(viewPoint.x * scale) - renderer.currentViewportSize.x / 2,
            renderer.currentViewportSize.y / 2 - Float(viewPoint.y * scale)
        )
        renderer.camera.zoom(by: Float(factor), around: anchor)
        renderer.setNeedsRedraw()
    }

    private func updateHover(at viewPoint: CGPoint?) {
        guard let renderer else { return }
        let index = viewPoint.flatMap {
            renderer.simulation.node(at: worldPoint(from: $0), tolerance: hitTolerance)
        }
        guard index != renderer.highlightedNode else { return }
        renderer.highlightedNode = index
        interactionDelegate?.graphDidHover(nodeAt: index)
        renderer.setNeedsRedraw()
    }
}

// MARK: - macOS input

#if os(macOS)
extension GraphMetalView {
    private func installGestureRecognizers() {
        let magnification = NSMagnificationGestureRecognizer(
            target: self,
            action: #selector(handleMagnification(_:))
        )
        addGestureRecognizer(magnification)

        // A tracking area is what makes hover work; without it mouseMoved never fires.
        let tracking = NSTrackingArea(
            rect: .zero,
            options: [.activeInKeyWindow, .inVisibleRect, .mouseMoved, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(tracking)
    }

    public override var acceptsFirstResponder: Bool { true }

    private func localPoint(_ event: NSEvent) -> CGPoint {
        // AppKit's y axis points up; flip so both platforms share one conversion path.
        let point = convert(event.locationInWindow, from: nil)
        return CGPoint(x: point.x, y: bounds.height - point.y)
    }

    public override func mouseDown(with event: NSEvent) {
        beginDrag(at: localPoint(event))
    }

    public override func mouseDragged(with event: NSEvent) {
        continueDrag(to: localPoint(event))
    }

    public override func mouseUp(with event: NSEvent) {
        endDrag(at: localPoint(event), wasClick: event.clickCount > 0)
    }

    public override func mouseMoved(with event: NSEvent) {
        updateHover(at: localPoint(event))
    }

    public override func mouseExited(with event: NSEvent) {
        updateHover(at: nil)
    }

    public override func scrollWheel(with event: NSEvent) {
        guard let renderer else { return }
        let point = localPoint(event)
        if event.modifierFlags.contains(.command) {
            zoom(by: 1 + event.scrollingDeltaY * 0.01, at: point)
        } else {
            let scale = drawableScaleFactor
            let delta = SIMD2<Float>(
                Float(event.scrollingDeltaX * scale),
                Float(-event.scrollingDeltaY * scale)
            )
            renderer.camera.center -= delta / max(renderer.camera.scale, 0.0001)
            renderer.setNeedsRedraw()
        }
    }

    @objc private func handleMagnification(_ recognizer: NSMagnificationGestureRecognizer) {
        let point = recognizer.location(in: self)
        zoom(
            by: 1 + recognizer.magnification,
            at: CGPoint(x: point.x, y: bounds.height - point.y)
        )
        recognizer.magnification = 0
    }
}
#endif

// MARK: - iOS input

#if !os(macOS)
extension GraphMetalView {
    private func installGestureRecognizers() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        addGestureRecognizer(pan)

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinch)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let point = recognizer.location(in: self)
        switch recognizer.state {
        case .began:
            beginDrag(at: point)
        case .changed:
            continueDrag(to: point)
        case .ended, .cancelled, .failed:
            endDrag(at: point, wasClick: false)
        default:
            break
        }
    }

    @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        guard recognizer.state == .changed || recognizer.state == .began else { return }
        zoom(by: recognizer.scale, at: recognizer.location(in: self))
        recognizer.scale = 1
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard let renderer, recognizer.state == .ended else { return }
        let point = recognizer.location(in: self)
        let world = worldPoint(from: point)
        if let index = renderer.simulation.node(at: world, tolerance: hitTolerance) {
            renderer.selectedNode = index
            renderer.highlightedNode = index
            interactionDelegate?.graphDidActivate(nodeAt: index)
        } else {
            renderer.selectedNode = nil
            renderer.highlightedNode = nil
            interactionDelegate?.graphDidClearSelection()
        }
        renderer.setNeedsRedraw()
    }
}
#endif
