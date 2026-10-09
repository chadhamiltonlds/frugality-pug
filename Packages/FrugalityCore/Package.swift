// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FrugalityCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "FrugalityCore", targets: ["FrugalityCore"])
    ],
    targets: [
        .target(
            name: "FrugalityCore",
            resources: [.copy("Resources/tax")]
        ),
        .testTarget(
            name: "FrugalityCoreTests",
            dependencies: ["FrugalityCore"]
        )
    ]
)
