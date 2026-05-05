// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TwentyGuard",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "TwentyGuardCore",
            targets: ["TwentyGuardCore"]
        ),
        .executable(
            name: "TwentyGuard",
            targets: ["TwentyGuard"]
        ),
    ],
    targets: [
        .target(
            name: "TwentyGuardCore",
            dependencies: []
        ),
        .executableTarget(
            name: "TwentyGuard",
            dependencies: ["TwentyGuardCore"],
            resources: [
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "TwentyGuardCoreTests",
            dependencies: ["TwentyGuardCore"]
        ),
    ]
)
