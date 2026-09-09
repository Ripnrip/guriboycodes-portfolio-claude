import Foundation

/// Tunables for the force simulation.
///
/// The defaults are chosen for a personal vault — a few hundred to a few thousand notes,
/// sparse, with a handful of hubs. `idealLength` is the one worth exposing in settings:
/// it sets how spread out the graph feels.
public struct GraphLayoutParameters: Sendable, Equatable {
    /// Strength of the all-pairs repulsion.
    public var repulsion: Float
    /// Spring constant pulling linked notes together.
    public var springStrength: Float
    /// Rest length of an edge, in world units.
    public var idealLength: Float
    /// Velocity retained each step; below 1 the layout settles instead of oscillating.
    public var damping: Float
    /// Pull toward the origin, which keeps disconnected components from drifting away.
    public var gravity: Float
    /// Speed ceiling, which stops a badly-conditioned first frame from flinging nodes.
    public var maxSpeed: Float
    /// Added to squared distance so coincident nodes produce finite force.
    public var softening: Float
    /// Fixed timestep. Decoupled from frame rate so a 120 Hz display and a 60 Hz one
    /// converge to the same layout.
    public var timeStep: Float
    /// Simulation steps per frame.
    public var stepsPerFrame: Int
    /// Kinetic energy per node below which the simulation is considered settled.
    public var settleThreshold: Float

    public static let `default` = GraphLayoutParameters(
        repulsion: 900,
        springStrength: 0.09,
        idealLength: 55,
        damping: 0.86,
        gravity: 0.012,
        maxSpeed: 240,
        softening: 12,
        timeStep: 1.0 / 60.0,
        stepsPerFrame: 1,
        settleThreshold: 0.02
    )

    public init(
        repulsion: Float,
        springStrength: Float,
        idealLength: Float,
        damping: Float,
        gravity: Float,
        maxSpeed: Float,
        softening: Float,
        timeStep: Float,
        stepsPerFrame: Int,
        settleThreshold: Float
    ) {
        self.repulsion = repulsion
        self.springStrength = springStrength
        self.idealLength = idealLength
        self.damping = damping
        self.gravity = gravity
        self.maxSpeed = maxSpeed
        self.softening = softening
        self.timeStep = timeStep
        self.stepsPerFrame = stepsPerFrame
        self.settleThreshold = settleThreshold
    }

    /// Scales the parameters so graphs of very different sizes settle at a similar pace.
    ///
    /// Repulsion is divided by node count because total repulsive force on a node grows
    /// linearly with the number of other nodes; without this a large graph explodes and a
    /// small one collapses.
    func normalized(forNodeCount count: Int) -> GraphLayoutParameters {
        guard count > 1 else { return self }
        var copy = self
        let scale = Float(count).squareRoot()
        copy.repulsion = repulsion * scale
        copy.idealLength = idealLength * min(2.5, max(0.6, scale / 12))
        return copy
    }
}
