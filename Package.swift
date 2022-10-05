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
		.package(
			url: "https://github.com/pointfreeco/swift-composable-architecture",
			branch: "protocol-beta"
		),
		// Format code
		.package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.50.0"),
	],
	targets: [
		// Targets sorted lexicographically, placing `testTarget` just after `target`.

		// For `swiftformat`: https://github.com/nicklockwood/SwiftFormat#1-create-a-buildtools-folder--packageswift
		.target(name: "_BuildTools"),
		.target(
			name: "AccountDetailsFeature",
			dependencies: [
				"AccountListFeature",
				"Address",
				"AggregatedValueFeature",
				"Asset",
				"AssetsViewFeature",
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
				"AccountPortfolio",
				"Address",
				"Asset",
				"FungibleTokenListFeature",
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
			name: "AccountPortfolio",
			dependencies: [
				"Address",
				"AppSettings",
				"Asset",
				"Common",
			]
		),
		.testTarget(
			name: "AccountPortfolioTests",
			dependencies: [
				"AccountPortfolio",
				tca,
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
				"AccountPortfolio",
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
				"WalletRemover",
				// ^^^ Sort lexicographically ^^^
			]
		),
		.testTarget(
			name: "AppFeatureTests",
			dependencies: [
				"AppFeature",
				"SplashFeature",
				"TestUtils",
				"Wallet",
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
			name: "Asset",
			dependencies: [
				"Address",
			]
		),
		.testTarget(
			name: "AssetTests",
			dependencies: [
				"Asset",
				"TestUtils",
			]
		),
		.target(
			name: "AssetsViewFeature",
			dependencies: [
				"Asset",
				"Common",
				"FungibleTokenListFeature",
				"NonFungibleTokenListFeature",
				tca,
			]
		),
		.testTarget(
			name: "AssetsViewFeatureTests",
			dependencies: [
				"AssetsViewFeature",
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
			name: "FungibleTokenListFeature",
			dependencies: [
				"Asset",
				"Common",
				tca,
			]
		),
		.testTarget(
			name: "FungibleTokenListFeatureTests",
			dependencies: [
				"Asset",
				"FungibleTokenListFeature",
				tca,
				"TestUtils",
			]
		),
		.target(
			name: "HomeFeature",
			dependencies: [
				// ˅˅˅ Sort lexicographically ˅˅˅
				"AccountListFeature",
				"AccountDetailsFeature",
				"AccountPortfolio",
				"AccountPreferencesFeature",
				"Address",
				"AppSettings",
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
				"AccountPortfolio",
				"AccountListFeature",
				"Address",
				"Asset",
				"FungibleTokenListFeature",
				"HomeFeature",
				"NonFungibleTokenListFeature",
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
				"AppSettings",
				"AccountPortfolio",
				"HomeFeature",
				"PasteboardClient",
				"SettingsFeature",
				tca,
				"WalletRemover",
				// ^^^ Sort lexicographically ^^^
			]
		),
		.testTarget(
			name: "MainFeatureTests",
			dependencies: [
				"MainFeature",
				"TestUtils",
				"WalletRemover",
			]
		),
		.target(
			name: "NonFungibleTokenListFeature",
			dependencies: [
				"Asset",
				"Common",
				tca,
			]
		),
		.testTarget(
			name: "NonFungibleTokenListFeatureTests",
			dependencies: [
				"NonFungibleTokenListFeature",
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
				"UserDefaultsClient",
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
		.target(
			name: "WalletRemover",
			dependencies: [
				"UserDefaultsClient",
				tca,
			]
		),
		.testTarget(
			name: "WalletRemoverTests",
			dependencies: [
				"UserDefaultsClient",
				"TestUtils",
				"WalletRemover",
				tca,
			]
		),
	]
)
