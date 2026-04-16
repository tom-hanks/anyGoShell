// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "anyGoShell",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "anyGoShell",
            targets: ["anyGoShell"]
        )
    ],
    targets: [
        .executableTarget(
            name: "anyGoShell",
            path: "Sources",
            resources: [
                .copy("../Resources")
            ]
        )
    ]
)
