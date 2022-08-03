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
		.package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.38.2"),

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
				"HomeFeature",
				"MainFeature",
				"OnboardingFeature",
				"ProfileLoader",
				"SettingsFeature",
				"SplashFeature",
				"UserDefaultsClient",
				"Wallet",
				"WalletLoader",
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
			name: "HomeFeature",
			dependencies: [
				// ˅˅˅ Sort lexicographically ˅˅˅
				"Common",
				tca,
				"Wallet",
				// ^^^ Sort lexicographically ^^^
			]
		),
		.testTarget(
			name: "HomeFeatureTests",
			dependencies: [
				"HomeFeature",
				"TestUtils",
			]
		),
		.target(
			name: "MainFeature",
			dependencies: [
				// ˅˅˅ Sort lexicographically ˅˅˅
				"Common",
				"HomeFeature",
				tca,
				"UserDefaultsClient",
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
				"UserDefaultsClient", // replace with `ProfileCreator`
				"Wallet",
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
			name: "ProfileLoader",
			dependencies: [
				"Common",
				"Profile",
				tca,
				"UserDefaultsClient",
			]
		),
		.testTarget(
			name: "ProfileLoaderTests",
			dependencies: [
				"ProfileLoader",
				"TestUtils",
			]
		),
		.target(
			name: "SettingsFeature",
			dependencies: [
				// ˅˅˅ Sort lexicographically ˅˅˅
				tca,
				// ^^^ Sort lexicographically ^^^
			]
		),
		// FIXME: Source files for target SettingsFeatureTests should be located under 'Tests/SettingsFeatureTests', or a custom sources path can be set with the 'path' property in Package.swift
		//        .testTarget(
		//            name: "SettingsFeatureTests",
		//            dependencies: [
		//                "SettingsFeature",
		//                "TestUtils",
		//            ]
		//        ),
		.target(
			name: "SplashFeature",
			dependencies: [
				// ˅˅˅ Sort lexicographically ˅˅˅
				"Common",
				"ProfileLoader",
				tca,
				"Wallet",
				"WalletLoader",
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
		.target(
			name: "WalletLoader",
			dependencies: [
				"Common",
				"Profile",
				"Wallet",
				tca,
			]
		),
		.testTarget(
			name: "WalletLoaderTests",
			dependencies: [
				"WalletLoader",
				"TestUtils",
			]
		),
	]
)
