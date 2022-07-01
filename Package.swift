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
		.iOS(.v15), // `task` in SwiftUI
	],
	products: [
		.library(
			name: "AppFeature",
			targets: ["AppFeature"]
		),
	],
	dependencies: [
		// TCA - ComposableArchitecture used as architecture
		.package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.38.1"),

		// Format code
		.package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.49.11"),
	],
	targets: [
		// Targets sorted lexicographically, placing `testTarget` just after `target`.

		// For `swiftformat`: https://github.com/nicklockwood/SwiftFormat#1-create-a-buildtools-folder--packageswift
		.target(name: "_BuildTools"),

		.target(
			name: "AppFeature",
			dependencies: [
				// ˅˅˅ Sort lexicographically ˅˅˅
				tca,
				"MainFeature",
				"OnboardingFeature",
				"SplashFeature",
				"Wallet",
				// ^^^ Sort lexicographically ^^^
			]
		),
		.testTarget(
			name: "AppFeatureTests",
			dependencies: [
				"AppFeature",
				"TestUtils",
			]
		),
		.target(
			name: "Common",
			dependencies: [
			]
		),
		.testTarget(
			name: "CommonTests",
			dependencies: [
				"Common",
				"TestUtils",
			]
		),
		.target(
			name: "MainFeature",
			dependencies: [
				// ˅˅˅ Sort lexicographically ˅˅˅
				"Common",
				tca,
				"Wallet",
				// ^^^ Sort lexicographically ^^^
			]
		),
		.testTarget(
			name: "MainFeatureTests",
			dependencies: [
				"MainFeature",
				"TestUtils",
			]
		),
		.target(
			name: "OnboardingFeature",
			dependencies: [
				// ˅˅˅ Sort lexicographically ˅˅˅
				"Common",
				tca,
				// ^^^ Sort lexicographically ^^^
			]
		),
		.testTarget(
			name: "OnboardingFeatureTests",
			dependencies: [
				"OnboardingFeature",
				"TestUtils",
			]
		),
		.target(
			name: "Profile",
			dependencies: [
				"Common",
			]
		),
		.testTarget(
			name: "ProfileTests",
			dependencies: [
				"Profile",
				"TestUtils",
			]
		),
		.target(
			name: "SplashFeature",
			dependencies: [
				// ˅˅˅ Sort lexicographically ˅˅˅
				"Common",
				tca,
				"Wallet",
				// ^^^ Sort lexicographically ^^^
			]
		),
		.testTarget(
			name: "SplashFeatureTests",
			dependencies: [
				"SplashFeature",
				"TestUtils",
			]
		),
		.target(
			name: "TestUtils",
			dependencies: [
				"Common",
				tca,
			]
		),
		.target(
			name: "UserDefaultsClient",
			dependencies: [
				tca,
			]
		),
		.testTarget(
			name: "UserDefaultsClientTests",
			dependencies: [
				"UserDefaultsClient",
				"TestUtils",
			]
		),
		.target(
			name: "Wallet",
			dependencies: [
				"Common",
				"Profile",
				tca,
			]
		),
		.testTarget(
			name: "WalletTests",
			dependencies: [
				"Wallet",
				"TestUtils",
			]
		),
	]
)
