// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TwentyTwentyTwenty",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "TwentyTwentyTwenty",
            targets: ["TwentyTwentyTwenty"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "TwentyTwentyTwenty",
            dependencies: [],
            resources: [
                .copy("Resources")
            ]
        ),
    ]
)
