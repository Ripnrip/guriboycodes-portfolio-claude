import Foundation
import VaultCore

/// Generates plausible graphs for previews, benchmarks, and the first run of the app
/// before a vault has been opened.
///
/// Uses preferential attachment, so the degree distribution has the same long tail a real
/// vault does: a few heavily-linked hub notes and a long tail of leaves. A uniformly
/// random graph looks nothing like a knowledge base and would make the layout parameters
/// look better tuned than they are.
public enum SyntheticGraph {
    public static func barabasiAlbert(
        nodeCount: Int,
        edgesPerNode: Int = 2,
        groupCount: Int = 6,
        seed: UInt64 = 0x5EED
    ) -> GraphSnapshot {
        guard nodeCount > 1 else { return .empty }
        var random = SplitMix64(seed: seed)

        let nodes = (0..<nodeCount).map { index in
            (
                id: NoteID(rawValue: "synthetic-\(index)"),
                label: "Note \(index)",
                group: Int(random.next() % UInt64(max(groupCount, 1)))
            )
        }

        // Repeated endpoints act as a weighted urn: a node appears once per edge it has,
        // so the chance of attracting the next edge is proportional to current degree.
        var urn: [Int] = [0]
        var edges: [GraphSnapshot.Edge] = []
        var seen = Set<Int64>()

        for index in 1..<nodeCount {
            let attachments = min(edgesPerNode, index)
            var chosen = Set<Int>()
            var attempts = 0
            while chosen.count < attachments && attempts < attachments * 8 {
                attempts += 1
                let candidate = urn[Int(random.next() % UInt64(urn.count))]
                if candidate != index { chosen.insert(candidate) }
            }
            for target in chosen {
                let key = Int64(min(index, target)) << 32 | Int64(max(index, target))
                guard seen.insert(key).inserted else { continue }
                edges.append(
                    GraphSnapshot.Edge(
                        source: index,
                        target: target,
                        weight: Float(1 + random.next() % 3)
                    )
                )
                urn.append(index)
                urn.append(target)
            }
        }

        return GraphSnapshot(nodes: nodes, edges: edges)
    }

    /// A small hand-shaped graph for SwiftUI previews.
    public static func preview() -> GraphSnapshot {
        barabasiAlbert(nodeCount: 120, edgesPerNode: 2)
    }
}

/// A tiny deterministic generator, so a "random" graph is reproducible between runs and
/// across machines. Reaching for `SystemRandomNumberGenerator` here would make a
/// performance regression impossible to bisect.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
