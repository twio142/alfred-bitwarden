// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "bw-alfred",
    platforms: [.macOS("15.0")],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-testing", from: "6.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "bw-alfred",
            path: "Sources"
        ),
        .testTarget(
            name: "bw-alfredTests",
            dependencies: [
                .target(name: "bw-alfred"),
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "Tests/bw-alfredTests"
        ),
    ]
)
