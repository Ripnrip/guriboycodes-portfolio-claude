// swift-tools-version: 6.0
import PackageDescription

// VaultCore and MarkdownKit hold the pure logic and depend on neither Realm nor Metal, so
// they build and test anywhere — including Linux CI. GraphEngine needs Metal, which only
// exists on Apple platforms, so it joins the package only when the host can compile it.

var products: [Product] = [
    .library(name: "VaultCore", targets: ["VaultCore"]),
    .library(name: "MarkdownKit", targets: ["MarkdownKit"]),
]

var targets: [Target] = [
    .target(name: "VaultCore"),
    .target(name: "MarkdownKit", dependencies: ["VaultCore"]),
    .testTarget(name: "VaultCoreTests", dependencies: ["VaultCore"]),
    .testTarget(name: "MarkdownKitTests", dependencies: ["MarkdownKit", "VaultCore"]),
]

#if os(macOS)
products.append(.library(name: "GraphEngine", targets: ["GraphEngine"]))
targets.append(
    .target(
        name: "GraphEngine",
        dependencies: ["VaultCore"],
        resources: [.process("Shaders")]
    )
)
targets.append(.testTarget(name: "GraphEngineTests", dependencies: ["GraphEngine", "VaultCore"]))
#endif

let package = Package(
    name: "LatticeKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: products,
    targets: targets
)
