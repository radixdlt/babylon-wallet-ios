// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let tca: Target.Dependency = .product(
	name: "ComposableArchitecture",
	package: "swift-composable-architecture"
)

let profile: Target.Dependency = .product(
	name: "Profile",
	package: "swift-profile"
)

let keychainClient: Target.Dependency = .product(
	name: "KeychainClient",
	package: "swift-profile"
)

let bigInt: Target.Dependency = .product(
	name: "BigInt",
	package: "BigInt"
)

let engineToolkit: Target.Dependency = .product(
	name: "EngineToolkit",
	package: "swift-engine-toolkit"
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
		.library(
			name: "CreateAccountFeature",
			targets: ["CreateAccountFeature"]
		),
		.library(
			name: "IncomingConnectionRequestFromDappReviewFeature",
			targets: ["IncomingConnectionRequestFromDappReviewFeature"]
		),
		.library(
			name: "ImportProfileFeature",
			targets: ["ImportProfileFeature"]
		),

	],
	dependencies: [
		// TCA - ComposableArchitecture used as architecture
		.package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.43.0"),
		// Format code
		.package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.50.2"),
		// BigInt
		.package(url: "https://github.com/attaswift/BigInt.git", from: "5.3.0"),

		.package(url: "git@github.com:radixdlt/swift-profile.git", from: "0.0.19"),

		.package(url: "git@github.com:radixdlt/swift-engine-toolkit.git", from: "0.0.1"),
	],
	targets: [
		// Targets sorted lexicographically, placing `testTarget` just after `target`.

		// For `swiftformat`: https://github.com/nicklockwood/SwiftFormat#1-create-a-buildtools-folder--packageswift
		.target(name: "_BuildTools"),
		.target(
			name: "AccountDetailsFeature",
			dependencies: [
				"AccountListFeature",
				"AggregatedValueFeature",
				"Asset",
				"AssetsViewFeature",
				engineToolkit,
				profile,
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
				"Asset",
				"FungibleTokenListFeature",
				profile,
				"ProfileClient",
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
				profile,
				"AppSettings",
				"Asset",
				"GatewayAPI",
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
				"Common",
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
			name: "AggregatedValueFeature",
			dependencies: [
				"Common",
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
				"ProfileClient",
				// ^^^ Sort lexicographically ^^^
			]
		),
		.testTarget(
			name: "AppFeatureTests",
			dependencies: [
				"AppFeature",
				"SplashFeature",
				"TestUtils",
				"ProfileClient",
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
				"Common",
				profile, // Address
				bigInt,
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
				profile, // Address
				bigInt,
				"DesignSystem",
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
				"Common",
				"DesignSystem",
				keychainClient,
				profile,
				tca,
				"ProfileClient",
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
			name: "DesignSystem",
			dependencies: [
			],
			resources: [
				.process("Fonts"),
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
			name: "GatewayAPI",
			dependencies: [
				"Asset",
				bigInt,
				"Common",
				engineToolkit,
				profile, // address
				tca, // XCTestDynamicOverlay + DependencyKey
			],
			exclude: [
				"CodeGen/Input/",
			]
		),
		.testTarget(
			name: "GatewayAPITests",
			dependencies: [
				"TestUtils",
				"GatewayAPI",
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
				profile,
				"AppSettings",
				"Common",
				"CreateAccountFeature",
				"PasteboardClient",
				tca,
				"ProfileClient",
				// ^^^ Sort lexicographically ^^^
			]
		),
		.testTarget(
			name: "HomeFeatureTests",
			dependencies: [
				"Asset",
				"FungibleTokenListFeature",
				"HomeFeature",
				"NonFungibleTokenListFeature",
				"TestUtils",
			]
		),

		.target(
			name: "ImportProfileFeature",
			dependencies: [
				"Common",
				profile,
				"ProfileClient",
				tca,
			]
		),
		.testTarget(
			name: "ImportProfileFeatureTests",
			dependencies: [
				"ImportProfileFeature",
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
				"ImportProfileFeature",
				profile,
				tca,
				"UserDefaultsClient", // replace with `ProfileCreator`
				"ProfileClient",
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
			name: "IncomingConnectionRequestFromDappReviewFeature",
			dependencies: [
				"Common",
				"DesignSystem",
				tca,
			]
		),
		.testTarget(
			name: "IncomingConnectionRequestFromDappReviewFeatureTests",
			dependencies: [
				"IncomingConnectionRequestFromDappReviewFeature",
				"TestUtils",
			]
		),
		.target(
			name: "ProfileLoader",
			dependencies: [
				profile,
				keychainClient,
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
				profile,
				"GatewayAPI",
				keychainClient,
				"ProfileClient",
				.product(name: "ProfileView", package: "swift-profile"),
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
				profile,
				"ProfileLoader",
				tca,
				"ProfileClient",
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
				profile, // Actually `Mnemonic`, Contains Data+Hex extension. FIXME: Extract Data+Hex functions to seperate repo, which Mnemonic and thus this TestUtils package can depend on.
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
			name: "ProfileClient",
			dependencies: [
				profile,
				"ProfileLoader",
				tca, // XCTestDynamicOverlay + DependencyKey
			]
		),
		.testTarget(
			name: "ProfileClientTests",
			dependencies: [
				"ProfileClient",
				"TestUtils",
			]
		),
	]
)
