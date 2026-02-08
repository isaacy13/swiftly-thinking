// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ThinkingDemo",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
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
