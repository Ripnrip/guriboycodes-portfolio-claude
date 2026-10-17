import Foundation

/// The isolation domain every Realm access lives in.
///
/// Realm objects are thread-confined and not `Sendable`. A plain Swift `actor` is **not**
/// sufficient: actors guarantee mutual exclusion, not thread stability, so an actor can
/// resume on a different cooperative-pool thread between awaits and Realm will trap.
///
/// Backing the actor with a `DispatchSerialQueue` as its executor fixes exactly that —
/// every hop runs on the one queue, so the same thread sees the Realm every time.
///
/// The rule that follows: nothing Realm-typed ever leaves this actor. The index returns
/// `VaultCore` value types only, which is the same snapshot-crossing-boundaries pattern
/// `GraphSimulation` uses for its GPU buffers.
@globalActor
public actor VaultIndexActor {
    public static let shared = VaultIndexActor()

    private let queue = DispatchSerialQueue(label: "codes.guriboy.lattice.vault-index")

    public nonisolated var unownedExecutor: UnownedSerialExecutor {
        queue.asUnownedSerialExecutor()
    }

    private init() {}
}
