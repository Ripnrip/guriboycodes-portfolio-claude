import Foundation

/// An immutable graph ready to hand to the layout engine.
///
/// Nodes are addressed by dense `Int` index rather than ``NoteID`` because the GPU needs
/// contiguous buffers. ``nodeIndex(for:)`` maps back when the UI needs to talk about a
/// real note.
///
/// Adjacency is stored in **CSR** (compressed sparse row) form. That is what lets the
/// attraction kernel be node-parallel: each thread walks exactly its own slice of
/// `adjacencyNeighbors`, so no two threads ever write the same force and the kernel needs
/// no atomics.
public struct GraphSnapshot: Sendable {
    public struct Node: Hashable, Sendable {
        public let id: NoteID
        public let label: String
        /// Number of incident edges; drives node radius on a log scale.
        public let degree: Int
        /// Cluster index used to pick a colour, typically from the note's primary tag.
        public let group: Int

        public init(id: NoteID, label: String, degree: Int, group: Int) {
            self.id = id
            self.label = label
            self.degree = degree
            self.group = group
        }
    }

    public struct Edge: Hashable, Sendable {
        public let source: Int
        public let target: Int
        public let weight: Float

        public init(source: Int, target: Int, weight: Float) {
            self.source = source
            self.target = target
            self.weight = weight
        }
    }

    public let nodes: [Node]
    public let edges: [Edge]

    /// `adjacencyOffsets[i] ..< adjacencyOffsets[i + 1]` is node `i`'s slice of the
    /// neighbour and weight arrays. Length is `nodes.count + 1`.
    public let adjacencyOffsets: [UInt32]
    /// Neighbour node indices, grouped by source node. Length is `2 * edges.count`
    /// because every edge is stored from both ends.
    public let adjacencyNeighbors: [UInt32]
    /// Edge weight parallel to ``adjacencyNeighbors``.
    public let adjacencyWeights: [Float]

    private let indexByID: [NoteID: Int]

    public var nodeCount: Int { nodes.count }
    public var edgeCount: Int { edges.count }
    public var isEmpty: Bool { nodes.isEmpty }

    public func nodeIndex(for id: NoteID) -> Int? { indexByID[id] }

    /// Builds a snapshot, computing degrees and CSR adjacency in one pass.
    ///
    /// Edges referencing an out-of-range endpoint are dropped rather than trapping: the
    /// index can legitimately race a file deletion, and a malformed edge should not take
    /// the graph view down with it.
    public init(nodes rawNodes: [(id: NoteID, label: String, group: Int)], edges rawEdges: [Edge]) {
        let count = rawNodes.count

        var indexByID = [NoteID: Int](minimumCapacity: count)
        for (offset, node) in rawNodes.enumerated() {
            indexByID[node.id] = offset
        }
        self.indexByID = indexByID

        let validEdges = rawEdges.filter {
            $0.source >= 0 && $0.source < count
                && $0.target >= 0 && $0.target < count
                && $0.source != $0.target
        }
        self.edges = validEdges

        // Degree, counting each undirected edge once per endpoint.
        var degrees = [Int](repeating: 0, count: count)
        for edge in validEdges {
            degrees[edge.source] += 1
            degrees[edge.target] += 1
        }

        self.nodes = rawNodes.enumerated().map { offset, node in
            Node(id: node.id, label: node.label, degree: degrees[offset], group: node.group)
        }

        // CSR: prefix-sum the degrees into offsets, then fill both directions.
        var offsets = [UInt32](repeating: 0, count: count + 1)
        var running: UInt32 = 0
        for i in 0..<count {
            offsets[i] = running
            running += UInt32(degrees[i])
        }
        offsets[count] = running

        var cursor = offsets  // advanced as we place each neighbour
        var neighbors = [UInt32](repeating: 0, count: Int(running))
        var weights = [Float](repeating: 0, count: Int(running))
        for edge in validEdges {
            let a = Int(cursor[edge.source])
            neighbors[a] = UInt32(edge.target)
            weights[a] = edge.weight
            cursor[edge.source] += 1

            let b = Int(cursor[edge.target])
            neighbors[b] = UInt32(edge.source)
            weights[b] = edge.weight
            cursor[edge.target] += 1
        }

        self.adjacencyOffsets = offsets
        self.adjacencyNeighbors = neighbors
        self.adjacencyWeights = weights
    }

    public static let empty = GraphSnapshot(nodes: [], edges: [])

    /// Neighbour indices of `index`, read straight out of the CSR arrays.
    public func neighbors(of index: Int) -> ArraySlice<UInt32> {
        guard index >= 0 && index < nodes.count else { return [] }
        return adjacencyNeighbors[Int(adjacencyOffsets[index])..<Int(adjacencyOffsets[index + 1])]
    }

    /// Breadth-first neighbourhood used by the "local graph" filter.
    ///
    /// Returns node indices within `depth` hops of `origin`, including `origin` itself.
    public func neighborhood(around origin: Int, depth: Int) -> Set<Int> {
        guard origin >= 0 && origin < nodes.count, depth >= 0 else { return [] }
        var visited: Set<Int> = [origin]
        var frontier = [origin]
        for _ in 0..<depth {
            var next: [Int] = []
            for node in frontier {
                for neighbor in neighbors(of: node) {
                    let candidate = Int(neighbor)
                    if visited.insert(candidate).inserted {
                        next.append(candidate)
                    }
                }
            }
            if next.isEmpty { break }
            frontier = next
        }
        return visited
    }

    /// Nodes with no edges at all — the "orphans" filter.
    public var orphanIndices: [Int] {
        nodes.indices.filter { nodes[$0].degree == 0 }
    }
}
