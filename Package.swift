// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "bw-alfred",
    platforms: [.macOS("15.0")],
    targets: [
        .executableTarget(
            name: "bw-alfred",
            path: "Sources"
        ),
        .testTarget(
            name: "bw-alfredTests",
            dependencies: [
                .target(name: "bw-alfred"),
            ],
            path: "Tests/bw-alfredTests"
        ),
    ]
)
