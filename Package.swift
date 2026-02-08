// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swiftly-thinking",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "SwiftlyThinking",
            targets: ["SwiftlyThinking"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftlyThinking",
            dependencies: []
        ),
        .testTarget(
            name: "SwiftlyThinkingTests",
            dependencies: ["SwiftlyThinking"]),
    ]
)
