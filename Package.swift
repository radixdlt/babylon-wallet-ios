// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let tca: Target.Dependency = .product(
    name: "ComposableArchitecture",
    package: "swift-composable-architecture"
)

let package = Package(
    name: "Babylon",
    platforms: [
        .macOS(.v12), // for development purposes
        .iOS(.v15) // `task` in SwiftUI
    ],
    products: [
        .library(
            name: "AppFeature",
            targets: ["AppFeature"]),
    ],
    dependencies: [
        // TCA - ComposableArchitecture used as architecture
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.38.1")
    ],
    targets: [
        // Targets sorted lexicographically, placing `testTarget` just after `target`.
        .target(
            name: "AppFeature",
            dependencies: [
                // ˅˅˅ Sort lexicographically ˅˅˅
                tca
                // ^^^ Sort lexicographically ^^^
            ]),
        .testTarget(
            name: "AppFeatureTests",
            dependencies: [
                "AppFeature"
            ]),
    ]
)
