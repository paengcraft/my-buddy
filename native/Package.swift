// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MyBuddyNative",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MyBuddy", targets: ["MyBuddyApp"]),
        .library(name: "MyBuddyCore", targets: ["MyBuddyCore"])
    ],
    targets: [
        .target(name: "MyBuddyCore"),
        .executableTarget(
            name: "MyBuddyApp",
            dependencies: ["MyBuddyCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "MyBuddyCoreTests",
            dependencies: ["MyBuddyCore"]
        )
    ]
)
