// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "PasteIt",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "PasteIt", targets: ["PasteIt"]),
        .library(name: "PasteItCore", targets: ["PasteItCore"])
    ],
    dependencies: [
        .package(path: "work/dependencies/Sparkle"),
        .package(path: "work/dependencies/swift-sdk"),
        .package(path: "work/dependencies/posthog-ios")
    ],
    targets: [
        .target(
            name: "PasteItCore",
            path: "Sources/PasteItCore",
            linkerSettings: [
                .linkedFramework("AppKit")
            ]
        ),
        .executableTarget(
            name: "PasteIt",
            dependencies: [
                "PasteItCore",
                .product(name: "Sparkle", package: "Sparkle"),
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "PostHog", package: "posthog-ios")
            ],
            path: "Sources/PasteIt",
            // Only runtime translations belong in the SwiftPM bundle. App icons
            // are installed once in the main bundle by the packaging scripts.
            resources: [
                .process("../../Resources/de.lproj"),
                .process("../../Resources/en.lproj"),
                .process("../../Resources/es.lproj"),
                .process("../../Resources/fr.lproj"),
                .process("../../Resources/ja.lproj"),
                .process("../../Resources/ko.lproj"),
                .process("../../Resources/pl.lproj"),
                .process("../../Resources/zh-Hans.lproj"),
                .process("../../Resources/zh-Hant.lproj")
            ],
            linkerSettings: [
                .linkedFramework("WebKit")
            ]
        ),
        .testTarget(
            name: "PasteItTests",
            dependencies: ["PasteItCore"],
            path: "Tests/PasteItTests"
        ),
        .testTarget(
            name: "PasteItIntegrationTests",
            dependencies: ["PasteIt", "PasteItCore"],
            path: "Tests/PasteItIntegrationTests"
        )
    ]
)
