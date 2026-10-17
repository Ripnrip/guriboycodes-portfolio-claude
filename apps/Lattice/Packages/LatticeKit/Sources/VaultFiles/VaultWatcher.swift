import Foundation

/// Notifies when something in the vault folder changes on disk.
///
/// This is a **latency optimisation, not a correctness mechanism.** macOS has FSEvents,
/// which is recursive and reliable. iOS has no equivalent — `NSFilePresenter` on a deep
/// tree is unreliable and `NSMetadataQuery` is documented as missing changes in
/// subdirectories of external ubiquity containers — so there the watcher reports itself
/// unsupported and the app falls back to an incremental crawl on activation.
///
/// Because the crawl is the guarantee, a missed event costs freshness, never consistency.
public final class VaultWatcher: @unchecked Sendable {
    /// Whether live watching works on this platform.
    public static var isSupported: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }

    /// Coalescing window. A single save often produces several filesystem events, and an
    /// editor writing atomically produces a create plus a rename; debouncing turns that
    /// burst into one re-crawl.
    private static let latency: CFTimeInterval = 0.4

    /// Holds the callback for the C context pointer.
    ///
    /// The stream retains *this*, never the watcher. Retaining the watcher would keep its
    /// reference count above zero for as long as the stream lived, so `deinit` — the thing
    /// meant to stop the stream — could never run.
    private final class CallbackBox {
        let onChange: @Sendable () -> Void
        init(_ onChange: @escaping @Sendable () -> Void) { self.onChange = onChange }
    }

    private let root: URL
    private let onChange: @Sendable () -> Void
    /// Serialises start/stop against each other and receives the stream's callbacks.
    private let queue = DispatchQueue(label: "codes.guriboy.lattice.vault-watcher")

    #if os(macOS)
    private var stream: FSEventStreamRef?
    private var boxPointer: UnsafeMutableRawPointer?
    #endif

    public init(vault: Vault, onChange: @escaping @Sendable () -> Void) {
        self.root = vault.root
        self.onChange = onChange
    }

    deinit {
        // No other reference can exist by definition, so tear down directly rather than
        // through `queue.sync` — which would deadlock if deinit landed on that queue.
        teardown()
    }

    public func start() {
        #if os(macOS)
        queue.sync {
            guard stream == nil else { return }

            let box = Unmanaged.passRetained(CallbackBox(onChange)).toOpaque()
            var context = FSEventStreamContext(
                version: 0,
                info: box,
                retain: nil,
                release: nil,
                copyDescription: nil
            )

            let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
                guard let info else { return }
                Unmanaged<CallbackBox>.fromOpaque(info).takeUnretainedValue().onChange()
            }

            guard let created = FSEventStreamCreate(
                kCFAllocatorDefault,
                callback,
                &context,
                [root.path] as CFArray,
                FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
                Self.latency,
                // FileEvents gives per-file granularity; WatchRoot also reports the vault
                // folder itself being moved or renamed out from under us.
                UInt32(
                    kFSEventStreamCreateFlagUseCFTypes
                        | kFSEventStreamCreateFlagFileEvents
                        | kFSEventStreamCreateFlagWatchRoot
                )
            ) else {
                Unmanaged<CallbackBox>.fromOpaque(box).release()
                return
            }

            FSEventStreamSetDispatchQueue(created, queue)
            FSEventStreamStart(created)
            stream = created
            boxPointer = box
        }
        #endif
    }

    public func stop() {
        #if os(macOS)
        queue.sync { teardown() }
        #endif
    }

    private func teardown() {
        #if os(macOS)
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
        }
        if let boxPointer {
            Unmanaged<CallbackBox>.fromOpaque(boxPointer).release()
            self.boxPointer = nil
        }
        #endif
    }
}
