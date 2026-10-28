// swift-tools-version: 6.2

import PackageDescription
import Foundation

// Fresh clones resolve the original dependency versions from their public repos.
// Opt in to the existing local repair copies for offline development on this Mac.
let usesLocalDependencies = ProcessInfo.processInfo.environment["PASTEL_USE_LOCAL_DEPENDENCIES"] == "1"
let appDependencies: [Package.Dependency] = usesLocalDependencies ? [
    .package(path: "work/dependencies/Sparkle"),
    .package(path: "work/dependencies/swift-sdk")
] : [
    .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.9.4"),
    .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", exact: "0.12.1")
]

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
    dependencies: appDependencies,
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
                .product(name: "MCP", package: "swift-sdk")
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
