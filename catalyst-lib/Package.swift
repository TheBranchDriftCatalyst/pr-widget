// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CatalystSwift",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "CatalystSwift", targets: ["CatalystSwift"]),
    ],
    targets: [
        .target(
            name: "CatalystSwift",
            path: "Sources/CatalystSwift"
        ),
        .testTarget(
            name: "CatalystSwiftTests",
            dependencies: ["CatalystSwift"],
            path: "Tests/CatalystSwiftTests"
        ),
    ]
)
