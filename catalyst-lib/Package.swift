// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CatalystSwift",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "CatalystSwift", targets: ["CatalystSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.3"),
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
