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
        .package(url: "https://github.com/CleanCocoa/Omnibar", from: "0.19.0"),
    ],
    targets: [
        .target(
            name: "TextKitAutoCompletion",
            dependencies: ["Omnibar"]
        ),
        .testTarget(
            name: "TextKitAutoCompletionTests",
            dependencies: ["TextKitAutoCompletion"]
        ),
    ]
)
