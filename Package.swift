// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LaunchdMonitor",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "LaunchdMonitor",
            path: "Sources/LaunchdMonitor"
        )
    ]
)
