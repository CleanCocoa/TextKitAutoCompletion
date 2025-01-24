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
        .package(url: "https://github.com/CleanCocoa/TextBuffer.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "TextKitAutoCompletion",
            dependencies: [
              "TextViewProxy",
              .product(name: "TextBuffer", package: "textbuffer"),
            ]
        ),
        .target(
            name: "TextViewProxy",
            dependencies: [],
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "TextKitAutoCompletionTests",
            dependencies: [
                .target(name: "TextKitAutoCompletion"),
                .product(name: "TextBuffer", package: "textbuffer"),
                .product(name: "TextBufferTesting", package: "textbuffer"),
            ]
        ),
    ]
)
