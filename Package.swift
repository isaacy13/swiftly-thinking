// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swiftly-thinking",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
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
