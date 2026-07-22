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
    dependencies: [
        .package(url: "https://github.com/typelift/SwiftCheck.git", exact: "0.12.0")
    ],
    targets: [
        .target(
            name: "HeartRateCoachCore",
            dependencies: [],
            path: "Sources/HeartRateCoachCore"
        ),
        .testTarget(
            name: "HeartRateCoachCoreTests",
            dependencies: [
                "HeartRateCoachCore",
                .product(name: "SwiftCheck", package: "SwiftCheck")
            ],
            path: "Tests/HeartRateCoachCoreTests"
        )
    ]
)
