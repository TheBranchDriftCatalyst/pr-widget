// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PArr",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "PArr", targets: ["PArr"]),
    ],
    dependencies: [
        .package(path: "../catalyst-swift"),
    ],
    targets: [
        .executableTarget(
            name: "PArr",
            dependencies: [
                .product(name: "CatalystSwift", package: "catalyst-swift"),
            ],
            path: "PRWidget",
            exclude: ["Resources/Info.plist", "Resources/PRWidget.entitlements"],
            resources: [
                .process("Resources/Assets.xcassets"),
                .copy("Resources/CHANGELOG.md"),
            ]
        ),
    ]
)
