// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Babylon",
	platforms: [
		.macOS(.v12), // for development purposes
		.iOS(.v15), // `task` in SwiftUI
	]
)

// MARK - Dependencies

package.dependencies += [
	// RDX Works Package depedencies
	.package(url: "git@github.com:radixdlt/Bite.git", from: "0.0.1"),
	.package(url: "git@github.com:radixdlt/Converse.git", from: "0.1.13"),
	.package(url: "git@github.com:radixdlt/swift-engine-toolkit.git", from: "0.0.9"),
	.package(url: "git@github.com:radixdlt/swift-profile.git", from: "0.0.27"),

	// BigInt
	.package(url: "https://github.com/attaswift/BigInt.git", from: "5.3.0"),

	// TCA - ComposableArchitecture used as architecture
	.package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.43.0"),

	// Format code
	.package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.50.2"),

	// Unfortunate GatewayAPI OpenAPI Generated Model dependency :/
	.package(url: "https://github.com/Flight-School/AnyCodable", from: "0.6.6"),
]

let tca: Target.Dependency = .product(
	name: "ComposableArchitecture",
	package: "swift-composable-architecture"
)

let dependencies: Target.Dependency = .product(
	name: "Dependencies",
	package: "swift-composable-architecture"
)

let profile: Target.Dependency = .product(
	name: "Profile",
	package: "swift-profile"
)

let converse: Target.Dependency = .product(
	name: "Converse",
	package: "Converse"
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

let bite: Target.Dependency = .product(
	name: "Bite",
	package: "Bite"
)

// MARK: - Abstract TCA Modules

extension Package {
	struct TCAModule {
		enum Category: String {
			case features = "Features"
			case clients = "Clients"
		}

		enum Tests {
			case no
			case yes(dependencies: [Target.Dependency])
		}

		let name: String
		let category: Category
		let dependencies: [Target.Dependency]
		let tests: Tests
		let isProduct: Bool
	}

	private func addTCAModule(_ module: TCAModule) {
		let targetName = module.name
		package.targets += [
			.target(name: targetName, dependencies: module.dependencies)
		]
		switch module.tests {
		case .no:
			break
		case .yes(let testDependencies):
			let testTargetName = targetName + "Tests"
			package.targets += [
				.testTarget(
					name: testTargetName,
					dependencies: [.target(name: targetName)] + testDependencies
				)
			]
		}
		if module.isProduct {
			package.products += [
				.library(name: targetName, targets: [targetName])
			]
		}
	}
}

// MARK: - Features

extension Package {
	func addFeature(name: String, dependencies: [Target.Dependency], tests: TCAModule.Tests, isProduct: Bool = true) {
		addTCAModule(.init(name: name, category: .features, dependencies: dependencies, tests: tests, isProduct: isProduct))
	}
}

package.addFeature(
	name: "AccountListFeature",
	dependencies: [
		"AccountPortfolio",
		"Asset",
		"FungibleTokenListFeature",
		profile,
		"ProfileClient",
		tca,
	],
	tests: .yes(dependencies: [
		"TestUtils",
	])
)

// MARK: - Clients

extension Package {
	func addClient(name: String, dependencies: [Target.Dependency], tests: TCAModule.Tests, isProduct: Bool = false) {
		addTCAModule(.init(name: name, category: .clients, dependencies: dependencies, tests: tests, isProduct: isProduct))
	}
}

package.products += [
	.library(
		name: "AppFeature",
		targets: ["AppFeature"]
	),
	.library(
		name: "CreateAccountFeature",
		targets: ["CreateAccountFeature"]
	),
	.library(
		name: "DesignSystem",
		targets: ["DesignSystem"]
	),
	.library(
		name: "HomeFeature",
		targets: ["HomeFeature"]
	),
	.library(
		name: "IncomingConnectionRequestFromDappReviewFeature",
		targets: ["IncomingConnectionRequestFromDappReviewFeature"]
	),
	.library(
		name: "ImportProfileFeature",
		targets: ["ImportProfileFeature"]
	),
]

// MARK: - Misc

package.targets += [
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
			"DesignSystem",
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
		name: "AccountPortfolio",
		dependencies: [
			"AppSettings",
			"Asset",
			bigInt,
			"Common",
			"GatewayAPI",
			profile,
			dependencies,
		]
	),
	.testTarget(
		name: "AccountPortfolioTests",
		dependencies: [
			"AccountPortfolio",
			dependencies,
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
			engineToolkit,
			"MainFeature",
			"OnboardingFeature",
			"PasteboardClient",
			"ProfileLoader",
			"ProfileClient",
			"SplashFeature",
			tca,
			"UserDefaultsClient",
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
			dependencies,
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
		],
		resources: [
			.process("Resources"),
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
			name: "EngineToolkitClient",
			dependencies: [
				bigInt,
				bite,
				"Common",
				dependencies,
				engineToolkit,
			]
		),
	.testTarget(
		name: "EngineToolkitClientTests",
		dependencies: [
			"EngineToolkitClient",
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
			.product(name: "AnyCodable", package: "AnyCodable"),
			"Asset",
			bigInt,
			"Common",
			engineToolkit,
			"EngineToolkitClient",
			profile, // address
			dependencies, // XCTestDynamicOverlay + DependencyKey
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
			"AppSettings",
			"Common",
			"CreateAccountFeature",
			engineToolkit,
			"IncomingConnectionRequestFromDappReviewFeature",
			"PasteboardClient",
			profile,
			"ProfileClient",
			tca,
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
			name: "ManageBrowserExtensionConnectionsFeature",
			dependencies: [
				"Common",
				converse,
				"DesignSystem",
				profile,
				tca,
			]
		),
	.testTarget(
		name: "ManageBrowserExtensionConnectionsFeatureTests",
		dependencies: [
			"ManageBrowserExtensionConnectionsFeature",
			"TestUtils",
		]
	),

		.target(
			name: "IncomingConnectionRequestFromDappReviewFeature",
			dependencies: [
				"Common",
				"DesignSystem",
				profile,
				"ProfileClient",
				tca,
			],
			resources: [
				.process("Resources"),
			]
		),
	.testTarget(
		name: "IncomingConnectionRequestFromDappReviewFeatureTests",
		dependencies: [
			"IncomingConnectionRequestFromDappReviewFeature",
			"ProfileClient",
			tca,
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
		],
		resources: [
			.process("profile_snapshot.json"),
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
			engineToolkit,
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
			engineToolkit,
			"ImportProfileFeature",
			profile,
			"ProfileClient",
			tca,
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
			dependencies,
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
			"ManageBrowserExtensionConnectionsFeature",
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
			dependencies,
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
			"EngineToolkitClient", // Create TX
			"GatewayAPI", // Create Account On Ledger => Submit TX
			profile,
			"ProfileLoader",
			dependencies, // XCTestDynamicOverlay + DependencyKey
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
