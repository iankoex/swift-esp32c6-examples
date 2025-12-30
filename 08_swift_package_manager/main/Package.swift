// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "App",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "App",
            type: .static,
            targets: ["App"])
    ],
    traits: [
        "Default",
        "Embedded",
        .default(enabledTraits: ["Default"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "App",
            dependencies: [],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("Embedded", .when(traits: ["Embedded"])),
            ]
        )
    ]
)
