// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ShotX",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ShotX",
            path: "Sources/ShotX"
        )
    ]
)
