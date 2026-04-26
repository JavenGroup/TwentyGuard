// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TwentyTwentyTwenty",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "TwentyTwentyTwentyCore",
            targets: ["TwentyTwentyTwentyCore"]
        ),
        .executable(
            name: "TwentyTwentyTwenty",
            targets: ["TwentyTwentyTwenty"]
        ),
    ],
    targets: [
        .target(
            name: "TwentyTwentyTwentyCore",
            dependencies: []
        ),
        .executableTarget(
            name: "TwentyTwentyTwenty",
            dependencies: ["TwentyTwentyTwentyCore"],
            resources: [
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "TwentyTwentyTwentyCoreTests",
            dependencies: ["TwentyTwentyTwentyCore"]
        ),
    ]
)
