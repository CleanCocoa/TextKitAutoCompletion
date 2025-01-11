// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TextKitAutoCompletion",
    platforms: [.macOS(.v10_13)],
    products: [
        .library(
            name: "TextKitAutoCompletion",
            targets: ["TextKitAutoCompletion", "TextViewProxy"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "TextKitAutoCompletion",
            dependencies: ["TextViewProxy"]
        ),
        .target(
            name: "TextViewProxy",
            dependencies: [],
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "TextKitAutoCompletionTests",
            dependencies: ["TextKitAutoCompletion"]
        ),
    ]
)
