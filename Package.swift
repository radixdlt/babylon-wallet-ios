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
		.library(
			name: "HomeFeature",
			targets: ["HomeFeature"]
		),
	],
	dependencies: [
		// TCA - ComposableArchitecture used as architecture
		.package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.39.0"),

		// Format code
		.package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.49.11"),
	],
	targets: [
		// Targets sorted lexicographically, placing `testTarget` just after `target`.

		// For `swiftformat`: https://github.com/nicklockwood/SwiftFormat#1-create-a-buildtools-folder--packageswift
		.target(name: "_BuildTools"),
		.target(
			name: "AccountDetailsFeature",
			dependencies: [
				"AccountListFeature",
				"AccountWorthFetcher",
				"Address",
				"AggregatedValueFeature",
				"AssetListFeature",
				"Profile",
				tca,
			]
		),
		.testTarget(
			name: "AccountDetailsFeatureTests",
			dependencies: [
				"AccountDetailsFeature",
				"TestUtils",
			]
		),
		.target(
			name: "AccountListFeature",
			dependencies: [
				"AccountWorthFetcher",
				"Address",
				"Profile",
				tca,
			]
		),
		.testTarget(
			name: "AccountListFeatureTests",
			dependencies: [
				"AccountListFeature",
				"TestUtils",
			]
		),
		.target(
			name: "AccountPreferencesFeature",
			dependencies: [
				tca,
			]
		),
		.testTarget(
			name: "AccountPreferencesFeatureTests",
			dependencies: [
				"AccountPreferencesFeature",
				"TestUtils",
			]
		),
		.target(
			name: "AccountWorthFetcher",
			dependencies: [
				"AppSettings",
				"Common",
				"Address",
			]
		),
		.testTarget(
			name: "AccountWorthFetcherTests",
			dependencies: [
				"AccountWorthFetcher",
				"TestUtils",
			]
		),
		.target(
			name: "Address",
			dependencies: [
			]
		),
		.testTarget(
			name: "AddressTests",
			dependencies: [
				"Address",
				"TestUtils",
			]
		),
		.target(
			name: "AggregatedValueFeature",
			dependencies: [
				tca,
			]
		),
		.testTarget(
			name: "AggregatedValueFeatureTests",
			dependencies: [
				"AggregatedValueFeature",
				"TestUtils",
			]
		),
		.target(
			name: "AppFeature",
			dependencies: [
				// ˅˅˅ Sort lexicographically ˅˅˅
				"AccountWorthFetcher",
				"AppSettings",
				"MainFeature",
				"OnboardingFeature",
				"PasteboardClient",
				"ProfileLoader",
				"SplashFeature",
				tca,
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
			name: "AppSettings",
			dependencies: [
				"Common",
				"UserDefaultsClient",
			]
		),
		.testTarget(
			name: "AppSettingsTests",
			dependencies: [
				"AppSettings",
				"TestUtils",
			]
		),
		.target(
			name: "AssetListFeature",
			dependencies: [
				"AccountWorthFetcher",
				tca,
			]
		),
		.testTarget(
			name: "AssetListFeatureTests",
			dependencies: [
				"AccountWorthFetcher",
				"AssetListFeature",
				"TestUtils",
			]
		),
		.target(
			name: "Common",
			dependencies: [
				"Address",
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
			name: "CreateAccountFeature",
			dependencies: [
				tca,
			]
		),
		.testTarget(
			name: "CreateAccountFeatureTests",
			dependencies: [
				"CreateAccountFeature",
				"TestUtils",
			]
		),
		.target(
			name: "HomeFeature",
			dependencies: [
				// ˅˅˅ Sort lexicographically ˅˅˅
				"AccountListFeature",
				"AccountDetailsFeature",
				"AccountPreferencesFeature",
				"AccountWorthFetcher",
				"Address",
				"AppSettings",
				"AssetListFeature",
				"Common",
				"CreateAccountFeature",
				"PasteboardClient",
				tca,
				"Wallet",
				// ^^^ Sort lexicographically ^^^
			]
		),
		.testTarget(
			name: "HomeFeatureTests",
			dependencies: [
				"AccountDetailsFeature",
				"AccountListFeature",
				"AccountWorthFetcher",
				"Address",
				"AssetListFeature",
				"HomeFeature",
				"Profile",
				"TestUtils",
			]
		),
		.target(
			name: "LocalAuthenticationClient",
			dependencies: []
		),
		.testTarget(
			name: "LocalAuthenticationClientTests",
			dependencies: [
				"LocalAuthenticationClient",
				"TestUtils",
			]
		),
		.target(
			name: "MainFeature",
			dependencies: [
				// ˅˅˅ Sort lexicographically ˅˅˅
				"AccountWorthFetcher",
				"AppSettings",
				"HomeFeature",
				"PasteboardClient",
				"SettingsFeature",
				tca,
				"UserDefaultsClient",
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
				"Profile",
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
			name: "PasteboardClient",
			dependencies: [
				tca,
			]
		),
		.testTarget(
			name: "PasteboardClientTests",
			dependencies: [
				"PasteboardClient",
				"TestUtils",
			]
		),
		.target(
			name: "Profile",
			dependencies: [
				"Address",
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
				"Profile",
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
				"Common",
				tca,
				// ^^^ Sort lexicographically ^^^
			]
		),
		.testTarget(
			name: "SettingsFeatureTests",
			dependencies: [
				"SettingsFeature",
				"TestUtils",
			]
		),
		.target(
			name: "SplashFeature",
			dependencies: [
				// ˅˅˅ Sort lexicographically ˅˅˅
				"Common",
				"Profile",
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
				"Profile",
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
