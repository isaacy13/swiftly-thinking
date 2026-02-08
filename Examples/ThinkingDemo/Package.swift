// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ThinkingDemo",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .executable(
            name: "ThinkingDemo",
            targets: ["ThinkingDemo"]
        )
    ],
    dependencies: [
        .package(name: "swiftly-thinking", path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "ThinkingDemo",
            dependencies: [
                .product(name: "SwiftlyThinking", package: "swiftly-thinking")
            ]
        )
    ]
)
