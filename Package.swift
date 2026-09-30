// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DynamicWallpaper",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "DynamicWallpaper",
            targets: ["DynamicWallpaper"]
        )
    ],
    targets: [
        .executableTarget(
            name: "DynamicWallpaper",
            dependencies: [],
            path: "Sources/DynamicWallpaper"
        )
    ]
)
