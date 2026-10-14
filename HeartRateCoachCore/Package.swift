// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HeartRateCoachCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "HeartRateCoachCore", targets: ["HeartRateCoachCore"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "HeartRateCoachCore",
            dependencies: [],
            path: "Sources/HeartRateCoachCore"
        ),
        .testTarget(
            name: "HeartRateCoachCoreTests",
            dependencies: ["HeartRateCoachCore"],
            path: "Tests/HeartRateCoachCoreTests"
        )
    ]
)
