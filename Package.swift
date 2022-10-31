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

// MARK: - Dependencies

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

// MARK: - Defining TCA Modules

extension Package {
	struct Module {
		enum Tests {
			case no
			case yes(nameSuffix: String = "Tests", dependencies: [Target.Dependency], resources: [Resource]? = nil)
		}

		let name: String
		let category: String
		let dependencies: [Target.Dependency]
		let resources: [Resource]?
		let tests: Tests
		let isProduct: Bool

		static func feature(name: String, dependencies: [Target.Dependency], resources: [Resource]? = nil, tests: Tests, isProduct: Bool = true) -> Self {
			.init(name: name, category: "Features", dependencies: dependencies, resources: resources, tests: tests, isProduct: isProduct)
		}

		static func client(name: String, dependencies: [Target.Dependency], resources: [Resource]? = nil, tests: Tests, isProduct: Bool = false) -> Self {
			.init(name: name, category: "Clients", dependencies: dependencies, resources: resources, tests: tests, isProduct: isProduct)
		}

		static func core(name: String, dependencies: [Target.Dependency], resources: [Resource]? = nil, tests: Tests, isProduct: Bool = false) -> Self {
			.init(name: name, category: "Core", dependencies: dependencies, resources: resources, tests: tests, isProduct: isProduct)
		}
	}

	func addModules(_ modules: [Module]) {
		for module in modules {
			addModule(module)
		}
	}

	private func addModule(_ module: Module) {
		let targetName = module.name
		package.targets += [
			.target(name: targetName, dependencies: module.dependencies, resources: module.resources),
		]
		switch module.tests {
		case .no:
			break
		case let .yes(nameSuffix, testDependencies, resources):
			let testTargetName = targetName + nameSuffix
			package.targets += [
				.testTarget(
					name: testTargetName,
					dependencies: [.target(name: targetName)] + testDependencies,
					resources: resources
				),
			]
		}
		if module.isProduct {
			package.products += [
				.library(name: targetName, targets: [targetName]),
			]
		}
	}
}

// MARK: - Features

package.addModules([
	.feature(
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
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.feature(
		name: "AccountListFeature",
		dependencies: [
			"AccountPortfolio",
			"Asset",
			"FungibleTokenListFeature",
			profile,
			"ProfileClient",
			tca,
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.feature(
		name: "AccountPreferencesFeature",
		dependencies: [
			"Common",
			tca,
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.feature(
		name: "AggregatedValueFeature",
		dependencies: [
			"Common",
			tca,
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.feature(
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
		],
		tests: .yes(
			dependencies: [
				"SplashFeature",
				"TestUtils",
				"ProfileClient",
			]
		)
	),
	.feature(
		name: "AssetsViewFeature",
		dependencies: [
			"Asset",
			"Common",
			"FungibleTokenListFeature",
			"NonFungibleTokenListFeature",
			tca,
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.feature(
		name: "CreateAccountFeature",
		dependencies: [
			"Common",
			"DesignSystem",
			keychainClient,
			profile,
			tca,
			"ProfileClient",
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.feature(
		name: "FungibleTokenListFeature",
		dependencies: [
			"Asset",
			"Common",
			tca,
		],
		tests: .yes(
			dependencies: [
				"Asset",
				tca,
				"TestUtils",
			]
		)
	),
	.feature(
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
		],
		tests: .yes(
			dependencies: [
				"Asset",
				"FungibleTokenListFeature",
				"NonFungibleTokenListFeature",
				"TestUtils",
			]
		)
	),
	.feature(
		name: "ImportProfileFeature",
		dependencies: [
			"Common",
			profile,
			"ProfileClient",
			tca,
		],
		tests: .yes(
			dependencies: ["TestUtils"],
			resources: [.process("profile_snapshot.json")]
		)
	),
	.feature(
		name: "IncomingConnectionRequestFromDappReviewFeature",
		dependencies: [
			"Common",
			"DesignSystem",
			profile,
			"ProfileClient",
			tca,
		],
		resources: [.process("Resources")],
		tests: .yes(
			dependencies: [
				"ProfileClient",
				tca,
				"TestUtils",
			]
		)
	),
	.feature(
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
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.feature(
		name: "ManageBrowserExtensionConnectionsFeature",
		dependencies: [
			"Common",
			converse,
			"DesignSystem",
			profile,
			tca,
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.feature(
		name: "NonFungibleTokenListFeature",
		dependencies: [
			"Asset",
			"Common",
			tca,
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.feature(
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
		],
		tests: .yes(
			dependencies: [
				"OnboardingFeature",
				"UserDefaultsClient",
			]
		)
	),
	.feature(
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
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.feature(
		name: "SplashFeature",
		dependencies: [
			// ˅˅˅ Sort lexicographically ˅˅˅
			"Common",
			profile,
			"ProfileLoader",
			tca,
			"ProfileClient",
			// ^^^ Sort lexicographically ^^^
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
])

// MARK: - Clients

// MARK: - Core

package.addModules([
	.core(
		name: "DesignSystem",
		dependencies: [],
		resources: [.process("Fonts")],
		tests: .no
	)
])

package.targets += [
	// Targets sorted lexicographically, placing `testTarget` just after `target`.

	// For `swiftformat`: https://github.com/nicklockwood/SwiftFormat#1-create-a-buildtools-folder--packageswift
	.target(name: "_BuildTools"),
	.testTarget(
		name: "AccountPortfolioTests",
		dependencies: [
			"AccountPortfolio",
			dependencies,
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
