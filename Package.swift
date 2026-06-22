// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ConsoleDock",
    platforms: [
        .iOS(.v12),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "ConsoleDock",
            targets: ["ConsoleDock"]
        ),
        .library(
            name: "ConsoleDockCore",
            targets: ["ConsoleDockCore"]
        )
    ],
    targets: [
        .target(
            name: "ConsoleDockCore",
            publicHeadersPath: "include"
        ),
        .target(
            name: "ConsoleDock",
            dependencies: ["ConsoleDockCore"]
        ),
        .testTarget(
            name: "ConsoleDockCoreTests",
            dependencies: ["ConsoleDockCore"]
        ),
        .testTarget(
            name: "ConsoleDockTests",
            dependencies: ["ConsoleDock", "ConsoleDockCore"]
        )
    ]
)
