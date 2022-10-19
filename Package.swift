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
	],
	dependencies: [
		// TCA - ComposableArchitecture used as architecture
		.package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.41.2"),
		// Format code
		.package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.50.1"),
        
        .package(url: "https://github.com/radixdlt/swift-profile", from: "0.0.5"),
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
				"WalletClient",
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
				"WalletClient",
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
                profile, // Address
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
                profile,
				"DesignSystem",
				"Common",
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
				"Common",
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
				"WalletClient",
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
                profile,
				tca,
				"UserDefaultsClient", // replace with `ProfileCreator`
				"WalletClient",
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
				"WalletClient",
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
			name: "WalletClient",
			dependencies: [
                profile,
                tca, // XCTestDynamicOverlay + DependencyKey
			]
		),
		.testTarget(
			name: "WalletClientTests",
			dependencies: [
				"WalletClient",
				"TestUtils",
			]
		),
		.target(
			name: "WalletLoader",
			dependencies: [
                profile,
                keychainClient,
				"WalletClient",
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
                keychainClient,
                "WalletClient",
				tca,
			]
		),
		.testTarget(
			name: "WalletRemoverTests",
			dependencies: [
				"TestUtils",
				"WalletRemover",
				tca,
			]
		),
	]
)
