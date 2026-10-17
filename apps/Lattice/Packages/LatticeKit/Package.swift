// swift-tools-version: 6.0
import PackageDescription

// Targets are split by what they must link against, so the fiddly logic stays testable:
//
//   VaultCore, MarkdownKit, VaultFiles  — no Realm, no Metal. Build and test anywhere,
//                                         including Linux CI.
//   GraphEngine                         — needs Metal.
//   VaultIndex, LatticeUI               — need Realm / SwiftUI.
//
// The Apple-only targets join the package only when the host can compile them, which is
// what keeps `swift test` useful off a Mac.

var products: [Product] = [
    .library(name: "VaultCore", targets: ["VaultCore"]),
    .library(name: "MarkdownKit", targets: ["MarkdownKit"]),
    .library(name: "VaultFiles", targets: ["VaultFiles"]),
]

var targets: [Target] = [
    .target(name: "VaultCore"),
    .target(name: "MarkdownKit", dependencies: ["VaultCore"]),
    .target(name: "VaultFiles", dependencies: ["VaultCore", "MarkdownKit"]),
    .testTarget(name: "VaultCoreTests", dependencies: ["VaultCore"]),
    .testTarget(name: "MarkdownKitTests", dependencies: ["MarkdownKit", "VaultCore"]),
    .testTarget(name: "VaultFilesTests", dependencies: ["VaultFiles", "VaultCore", "MarkdownKit"]),
]

var dependencies: [Package.Dependency] = []

#if os(macOS)
products.append(.library(name: "GraphEngine", targets: ["GraphEngine"]))
products.append(.library(name: "VaultIndex", targets: ["VaultIndex"]))
products.append(.library(name: "LatticeUI", targets: ["LatticeUI"]))

// Realm's local database only; Atlas Device Sync reached end of life in September 2025.
dependencies.append(
    .package(url: "https://github.com/realm/realm-swift.git", from: "20.0.0")
)

targets.append(
    .target(
        name: "GraphEngine",
        dependencies: ["VaultCore"],
        resources: [.process("Shaders")]
    )
)
targets.append(
    .target(
        name: "VaultIndex",
        dependencies: [
            "VaultCore",
            "MarkdownKit",
            "VaultFiles",
            .product(name: "RealmSwift", package: "realm-swift"),
        ]
    )
)
targets.append(
    .target(
        name: "LatticeUI",
        dependencies: ["VaultCore", "MarkdownKit", "VaultFiles", "VaultIndex", "GraphEngine"]
    )
)
targets.append(.testTarget(name: "GraphEngineTests", dependencies: ["GraphEngine", "VaultCore"]))
#endif

let package = Package(
    name: "LatticeKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: products,
    dependencies: dependencies,
    targets: targets
)
