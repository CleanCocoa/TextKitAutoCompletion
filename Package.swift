// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TextKitAutoCompletion",
    platforms: [.macOS(.v10_13)],
    products: [
        .library(
            name: "TextKitAutoCompletion",
            targets: ["TextKitAutoCompletion"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "TextKitAutoCompletion",
            dependencies: []
        ),
        .testTarget(
            name: "TextKitAutoCompletionTests",
            dependencies: ["TextKitAutoCompletion"]
        ),
    ]
)
