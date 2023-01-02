// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Babylon",
	defaultLocalization: "en",
	platforms: [
		.macOS(.v12), // for development purposes
		.iOS(.v15), // `task` in SwiftUI
	]
)

// MARK: - Dependencies

package.dependencies += [
	// RDX Works dependencies
	.package(url: "git@github.com:radixdlt/Converse.git", from: "0.2.1"),
	.package(url: "git@github.com:radixdlt/swift-engine-toolkit.git", branch: "implicit-deps"),

	// ~~~ THIRD PARTY ~~~
	// APPLE
	.package(url: "https://github.com/apple/swift-collections", from: "1.0.3"),
	.package(url: "https://github.com/apple/swift-async-algorithms", from: "0.0.3"),

	// PointFreeCo
	.package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.46.0"),
	.package(url: "https://github.com/pointfreeco/swift-nonempty", from: "0.4.0"),
	.package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.7.0"),
	.package(url: "https://github.com/pointfreeco/swiftui-navigation", from: "0.4.3"),

	// Other
	.package(url: "https://github.com/attaswift/BigInt", from: "5.3.0"),
	.package(url: "https://github.com/mxcl/LegibleError", from: "1.0.6"),
	.package(url: "https://github.com/sideeffect-io/AsyncExtensions", from: "0.5.1"),
	.package(url: "https://github.com/SwiftGen/SwiftGenPlugin", from: "6.6.0"),
	.package(url: "https://github.com/twostraws/CodeScanner", from: "2.2.1"),
	.package(url: "https://github.com/kean/Nuke", from: "11.3.1"),
	.package(url: "https://github.com/siteline/SwiftUI-Introspect", from: "0.1.4"),

	// Unfortunate GatewayAPI OpenAPI Generated Model dependency :/
	.package(url: "https://github.com/Flight-School/AnyCodable", from: "0.6.6"),
]

let asyncAlgorithms: Target.Dependency = .product(
	name: "AsyncAlgorithms",
	package: "swift-async-algorithms"
)

let asyncExtensions: Target.Dependency = .product(
	name: "AsyncExtensions",
	package: "AsyncExtensions"
)

let collections: Target.Dependency = .product(
	name: "Collections",
	package: "swift-collections"
)

let nonEmpty: Target.Dependency = .product(
	name: "NonEmpty",
	package: "swift-nonempty"
)

let tca: Target.Dependency = .product(
	name: "ComposableArchitecture",
	package: "swift-composable-architecture"
)

let dependencies: Target.Dependency = .product(
	name: "Dependencies",
	package: "swift-composable-architecture"
)

let tagged: Target.Dependency = .product(
	name: "Tagged",
	package: "swift-tagged"
)

let legibleError: Target.Dependency = .product(
	name: "LegibleError",
	package: "LegibleError"
)

let p2pConnection: Target.Dependency = .product(
	name: "P2PConnection",
	package: "Converse"
)

let p2pModels: Target.Dependency = .product(
	name: "P2PModels",
	package: "Converse"
)

let engineToolkit: Target.Dependency = .product(
	name: "EngineToolkit",
	package: "swift-engine-toolkit"
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
		let exclude: [String]
		let resources: [Resource]?
		let plugins: [Target.PluginUsage]?
		let tests: Tests
		let isProduct: Bool

		static func feature(
			name: String,
			dependencies: [Target.Dependency],
			exclude: [String] = [],
			resources: [Resource]? = nil,
			plugins: [Target.PluginUsage]? = nil,
			tests: Tests,
			isProduct: Bool = true
		) -> Self {
			.init(
				name: name,
				category: "Features",
				dependencies: dependencies,
				exclude: exclude,
				resources: resources,
				plugins: plugins,
				tests: tests,
				isProduct: isProduct
			)
		}

		static func client(
			name: String,
			dependencies: [Target.Dependency],
			exclude: [String] = [],
			resources: [Resource]? = nil,
			plugins: [Target.PluginUsage]? = nil,
			tests: Tests,
			isProduct: Bool = false
		) -> Self {
			.init(
				name: name,
				category: "Clients",
				dependencies: dependencies,
				exclude: exclude,
				resources: resources,
				plugins: plugins,
				tests: tests,
				isProduct: isProduct
			)
		}

		static func core(
			name: String,
			dependencies: [Target.Dependency],
			exclude: [String] = [],
			resources: [Resource]? = nil,
			plugins: [Target.PluginUsage]? = nil,
			tests: Tests,
			isProduct: Bool = false
		) -> Self {
			.init(
				name: name,
				category: "Core",
				dependencies: dependencies,
				exclude: exclude,
				resources: resources,
				plugins: plugins,
				tests: tests,
				isProduct: isProduct
			)
		}
	}

	func addModules(_ modules: [Module]) {
		for module in modules {
			addModule(module)
		}
	}

	private func addModule(_ module: Module) {
		let targetName = module.name
		let targetPath = "Sources/\(module.category)/\(targetName)"

		package.targets += [
			.target(
				name: targetName,
				dependencies: module.dependencies,
				path: targetPath,
				exclude: module.exclude,
				resources: module.resources,
				swiftSettings: [
					.unsafeFlags([
						"-Xfrontend", "-warn-concurrency",
						"-Xfrontend", "-enable-actor-data-race-checks",
					]),
				],
				plugins: module.plugins
			),
		]

		switch module.tests {
		case .no:
			break
		case let .yes(nameSuffix, testDependencies, resources):
			let testTargetName = targetName + nameSuffix
			let testTargetPath = "Tests/\(module.category)/\(testTargetName)"
			package.targets += [
				.testTarget(
					name: testTargetName,
					dependencies: [.target(name: targetName)] + testDependencies,
					path: testTargetPath,
					resources: resources,
					swiftSettings: [
						.unsafeFlags([
							"-Xfrontend", "-warn-concurrency",
							"-Xfrontend", "-enable-actor-data-race-checks",
						]),
					]
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
			"AccountPreferencesFeature",
			"Asset",
			"AssetsViewFeature",
			"DesignSystem",
			engineToolkit,
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
			"DesignSystem",
			"ErrorQueue",
			"FaucetClient",
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
			"DesignSystem",
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
			"ErrorQueue",
			"MainFeature",
			"OnboardingFeature",
			"PasteboardClient",
			"ProfileLoader",
			"ProfileClient",
			"Resources",
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
			engineToolkit,
			"ErrorQueue",
			"GatewayAPI",
			"KeychainClientDependency",
			"LocalAuthenticationClient",
			"ProfileClient",
			tca,
		],
		tests: .yes(
			dependencies: [
				"TestUtils",
				"UserDefaultsClient",
			]
		)
	),
	.feature(
		name: "FungibleTokenDetailsFeature",
		dependencies: [
			"DesignSystem",
			"PasteboardClient",
			"SharedModels",
			tca,
		],
		tests: .no
	),
	.feature(
		name: "FungibleTokenListFeature",
		dependencies: [
			"Asset",
			"Common",
			"DesignSystem",
			"FungibleTokenDetailsFeature",
			tca,
		],
		tests: .yes(
			dependencies: [
				"Asset",
				"DesignSystem",
				engineToolkit,
				tca,
				"TestUtils",
			]
		)
	),
	.feature(
		name: "GrantDappWalletAccessFeature",
		dependencies: [
			// ˅˅˅ Sort lexicographically ˅˅˅
			"Common",
			"CreateAccountFeature",
			"DesignSystem",
			"ErrorQueue",
			"ProfileClient",
			"SharedModels",
			tca,
			// ^^^ Sort lexicographically ^^^
		],
		tests: .yes(
			dependencies: [
				"ProfileClient",
				tca,
				"TestUtils",
			]
		)
	),
	.feature(
		name: "HandleDappRequests",
		dependencies: [
			collections,
			engineToolkit,
			"GrantDappWalletAccessFeature",
			"P2PConnectivityClient",
			"SharedModels",
			tca,
			"TransactionSigningFeature",
		], tests: .yes(dependencies: ["TestUtils"])
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
			"P2PConnectivityClient",
			"Common",
			"CreateAccountFeature",
			engineToolkit,
			"GrantDappWalletAccessFeature",
			"PasteboardClient",
			"ProfileClient",
			"SharedModels",
			tca,
			"TransactionSigningFeature",
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
			"DesignSystem",
			"ErrorQueue",
			"FileClient",
			"JSON",
			"KeychainClientDependency",
			"ProfileClient",
			tca,
		],
		tests: .yes(
			dependencies: ["TestUtils"],
			resources: [.process("profile_snapshot.json")]
		)
	),
	.feature(
		name: "MainFeature",
		dependencies: [
			// ˅˅˅ Sort lexicographically ˅˅˅
			"AppSettings",
			"AccountPortfolio",
			engineToolkit,
			"HandleDappRequests",
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
		name: "ManageP2PClientsFeature",
		dependencies: [
			// ˅˅˅ Sort lexicographically ˅˅˅
			"Common",
			p2pConnection,
			dependencies,
			"DesignSystem",
			"ErrorQueue",
			"NewConnectionFeature",
			"P2PConnectivityClient",
			"ProfileClient",
			"SharedModels",
			// ^^^ Sort lexicographically ^^^
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.feature(
		name: "ManageGatewayAPIEndpointsFeature",
		dependencies: [
			"Common",
			"CreateAccountFeature",
			dependencies,
			"ErrorQueue",
			"DesignSystem",
			"GatewayAPI",
			"ProfileClient",
			tca,
			"UserDefaultsClient",
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.feature(
		name: "NewConnectionFeature",
		dependencies: [
			"CameraPermissionClient",
			.product(name: "CodeScanner", package: "CodeScanner", condition: .when(platforms: [.iOS])),
			p2pConnection,
			"Common",
			"DesignSystem",
			"ErrorQueue",
			"P2PConnectivityClient",
			"SharedModels",
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
			"DesignSystem",
			engineToolkit,
			"PasteboardClient",
			"SharedModels",
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
			"DesignSystem",
			"CreateAccountFeature",
			"ImportProfileFeature",
			tca,
			// ^^^ Sort lexicographically ^^^
		],
		tests: .yes(
			dependencies: [
				"UserDefaultsClient",
				"TestUtils",
			]
		)
	),
	.feature(
		name: "SettingsFeature",
		dependencies: [
			// ˅˅˅ Sort lexicographically ˅˅˅
			"Common",
			engineToolkit,
			"ErrorQueue",
			"GatewayAPI",
			"KeychainClientDependency",
			"ManageP2PClientsFeature",
			"ManageGatewayAPIEndpointsFeature",
			"ProfileClient",
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
			"DesignSystem",
			"ErrorQueue",
			"LocalAuthenticationClient",
			"PlatformEnvironmentClient",
			"ProfileClient",
			"ProfileLoader",
			tca,
			// ^^^ Sort lexicographically ^^^
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.feature(
		name: "TransactionSigningFeature",
		dependencies: [
			// ˅˅˅ Sort lexicographically ˅˅˅
			"Common",
			"DesignSystem",
			"EngineToolkitClient",
			"ErrorQueue",
			"GatewayAPI",
			"ProfileClient",
			"SharedModels",
			tca,
			"TransactionClient",
			// ^^^ Sort lexicographically ^^^
		],
		tests: .yes(dependencies: [
			"TestUtils",
		])
	),
])

// MARK: - Clients

package.addModules([
	.client(
		name: "AccountPortfolio",
		dependencies: [
			"AppSettings",
			"Asset",
			"Common",
			engineToolkit,
			"GatewayAPI",
			dependencies,
		],
		tests: .yes(
			dependencies: [
				dependencies,
				"TestUtils",
			]
		)
	),
	.client(
		name: "AppSettings",
		dependencies: [
			"Common",
			dependencies,
			"JSON",
			"UserDefaultsClient",
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.client(
		name: "CameraPermissionClient",
		dependencies: [
			dependencies,
		],
		tests: .no
	),
	.client(
		name: "EngineToolkitClient",
		dependencies: [
			"Common",
			dependencies,
			engineToolkit,
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.client(
		name: "ErrorQueue",
		dependencies: [
			asyncAlgorithms,
			asyncExtensions,
			dependencies,
		],
		tests: .no
	),
	.client(
		name: "FaucetClient",
		dependencies: [
			"Common",
			dependencies,
			engineToolkit,
			"EngineToolkitClient",
			"GatewayAPI",
			"ProfileClient",
			"TransactionClient",
		], tests: .no
	),
	.client(
		name: "FileClient",
		dependencies: [
			dependencies,
		],
		tests: .no
	),
	.client(
		name: "GatewayAPI",
		dependencies: [
			.product(name: "AnyCodable", package: "AnyCodable"),
			"Asset",
			"Common",
			dependencies, // XCTestDynamicOverlay + DependencyKey
			engineToolkit,
			"EngineToolkitClient",
			"JSON",
			"ProfileClient",
		],
		exclude: [
			"CodeGen/Input/",
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.client(
		name: "JSON", // TODO: extract into external CoreDependencies package, or just as part of Common
		dependencies: [
			dependencies,
		],
		tests: .no
	),
	.client(
		name: "KeychainClientDependency",
		dependencies: [
			dependencies,
			engineToolkit,
		],
		tests: .no
	),
	.client(
		name: "LocalAuthenticationClient",
		dependencies: [
			dependencies,
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.client(
		name: "P2PConnectivityClient",
		dependencies: [
			asyncAlgorithms,
			asyncExtensions,
			"Common",
			dependencies,
			engineToolkit, // Model: SignTX contains Manifest, Account
			"JSON",
			p2pConnection,
			"ProfileClient",
			"Resources",
			"SharedModels",
		],
		tests: .yes(dependencies: [
			"TestUtils",
		])
	),
	.client(
		name: "PasteboardClient",
		dependencies: [dependencies],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.client(
		name: "PlatformEnvironmentClient",
		dependencies: [dependencies],
		tests: .no
	),
	.client(
		name: "ProfileClient",
		dependencies: [
			dependencies, // XCTestDynamicOverlay + DependencyKey
			"EngineToolkitClient", // Create TX
			"ProfileLoader",
			"SharedModels",
			"UserDefaultsClient",
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.client(
		name: "ProfileLoader",
		dependencies: [
			"Common",
			engineToolkit,
			"JSON",
			"KeychainClientDependency",
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.client(
		name: "TransactionClient",
		dependencies: [
			"GatewayAPI",
			dependencies,
			"ProfileClient",
		],
		tests: .yes(dependencies: [
			"TestUtils",
		])
	),
	.client(
		name: "UserDefaultsClient",
		dependencies: [dependencies],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
])

// MARK: - Core

package.addModules([
	.core(
		name: "Asset", // put in SharedModels?
		dependencies: [
			"Common",
			"EngineToolkitClient", // I know, this is very wrong. Apologies. Let's revisit our dependency levels post betanet.
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.core(
		name: "Common",
		dependencies: [
			"DesignSystem",
			engineToolkit,
			legibleError,
			"Resources",
			tagged,
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.core(
		name: "SharedModels",
		dependencies: [
			"Asset",
			"Common", // FIXME: it should be the other way around — Common should depend on SharedModels and @_exported import it. However, first we need to make Converse, EngineToolkit, etc. vend their own Model packages.
			engineToolkit, // FIXME: In `EngineToolkit` split out Models package
			collections,
			"Common", // FIXME: it should be the other way around — Common should depend on SharedModels and @_exported import it. However, first we need to make EngineToolkit, etc. vend their own Model packages.
			engineToolkit, // FIXME: In `EngineToolkit` split out Models package
			nonEmpty,
			p2pModels,
			p2pConnection,
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.core(
		name: "DesignSystem",
		dependencies: [
			.product(name: "Introspect", package: "SwiftUI-Introspect"),
			.product(name: "NukeUI", package: "Nuke"),
			"Resources",
			.product(name: "SwiftUINavigation", package: "swiftui-navigation"),
		],
		tests: .yes(
			dependencies: [
				"TestUtils",
			]
		),
		isProduct: true
	),
	.core(
		name: "Resources",
		dependencies: [],
		resources: [
			.process("Resources/"),
		],
		plugins: [
			.plugin(name: "SwiftGenPlugin", package: "SwiftGenPlugin"),
		],
		tests: .no,
		isProduct: true
	),
	.core(
		name: "TestUtils",
		dependencies: [
			engineToolkit,
			"Common",
			tca,
		],
		tests: .no
	),
])
