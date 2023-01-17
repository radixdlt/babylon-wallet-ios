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
			"PasteboardClient",
			"EngineToolkit",
			"Profile",

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
			"PasteboardClient",
			"ProfileClient",
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
			"EngineToolkit",
			"ErrorQueue",
			"MainFeature",
			"OnboardingFeature",
			"PasteboardClient",
			"ProfileLoader",
			"ProfileClient",
			"Resources",
			"SplashFeature",
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
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.feature(
		name: "CreateAccountFeature",
		dependencies: [
			"Common",
			"Cryptography",
			"DesignSystem",
			"EngineToolkit",
			"ErrorQueue",
			"GatewayAPI",
//			"KeychainClientDependency",
			"LocalAuthenticationClient",
			"ProfileClient",
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
		],
		tests: .yes(
			dependencies: [
				"Asset",
				"DesignSystem",
				"Profile",
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
			// ^^^ Sort lexicographically ^^^
		],
		tests: .yes(
			dependencies: [
				"ProfileClient",
				"TestUtils",
			]
		)
	),
	.feature(
		name: "HandleDappRequests",
		dependencies: [
			"GrantDappWalletAccessFeature",
			"P2PConnectivityClient",
			"Profile",
			"SharedModels",
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
			"EngineToolkit",
			"GrantDappWalletAccessFeature",
			"ProfileClient",
			"SharedModels",
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
			"Cryptography",
			"Common",
			"DesignSystem",
			"ErrorQueue",
			"FileClient",
			"JSON",
//			"KeychainClientDependency",
			"ProfileClient",
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
//			"EngineToolkit",
			"HandleDappRequests",
			"HomeFeature",
			"PasteboardClient",
			"SettingsFeature",
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
			"ErrorQueue",
			"DesignSystem",
			"GatewayAPI",
			"ProfileClient",
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
			.product(name: "CodeScanner", package: "CodeScanner", condition: .when(platforms: [.iOS])) {
				.package(url: "https://github.com/twostraws/CodeScanner", from: "2.2.1")
			},
			"Common",
			"DesignSystem",
			"ErrorQueue",
			"P2PConnectivityClient",
			"SharedModels",
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
			"EngineToolkit",
			"PasteboardClient",
			"SharedModels",
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
			"ErrorQueue",
			"GatewayAPI",
			"ManageP2PClientsFeature",
			"ManageGatewayAPIEndpointsFeature",
			"P2PConnectivityClient", // deleting connections when wallet is deleted
			"ProfileClient",
			"ProfileView",
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
			"EngineToolkit",
			"GatewayAPI",
			"Profile",
		],
		tests: .yes(
			dependencies: [
				"TestUtils",
			]
		)
	),
	.client(
		name: "AppSettings",
		dependencies: [
			"Common",
			"JSON",
			"UserDefaultsClient",
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.client(
		name: "CameraPermissionClient",
		dependencies: [],
		tests: .no
	),
	.client(
		name: "EngineToolkitClient",
		dependencies: [
			"Common",
			"Cryptography",
			"EngineToolkit",
			"Profile", // AccountAddress
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.client(
		name: "ErrorQueue",
		dependencies: [],
		tests: .no
	),
	.client(
		name: "FaucetClient",
		dependencies: [
			"Common",
			"EngineToolkit",
			"EngineToolkitClient",
			"GatewayAPI",
			"Profile",
			"ProfileClient",
			"TransactionClient",
		], tests: .no
	),
	.client(
		name: "FileClient",
		dependencies: [],
		tests: .no
	),
	.client(
		name: "GatewayAPI",
		dependencies: [
			.product(name: "AnyCodable", package: "AnyCodable") {
				// Unfortunate GatewayAPI OpenAPI Generated Model dependency :/
				.package(url: "https://github.com/Flight-School/AnyCodable", from: "0.6.6")
			},
			"Asset",
			"Common",
			"Cryptography",
			"EngineToolkit",
			"EngineToolkitClient",
			"JSON",
			"Profile", // address
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
		name: "JSON", // TODO: extract into Prelude package
		dependencies: [],
		tests: .no
	),
	.client(
		name: "LocalAuthenticationClient",
		dependencies: [],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.client(
		name: "P2PConnectivityClient",
		dependencies: [
			"Common",
			"EngineToolkit", // Model: SignTX contains Manifest
			"JSON",
			"Profile", // Account
			"ProfileClient",
			"P2PConnection",
			"Resources",
			"SharedModels",
		],
		tests: .yes(dependencies: [
			"TestUtils",
		])
	),
	.client(
		name: "PasteboardClient",
		dependencies: [],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.client(
		name: "PlatformEnvironmentClient",
		dependencies: [],
		tests: .no
	),
	.client(
		name: "ProfileClient",
		dependencies: [
			"Cryptography",
			"EngineToolkitClient", // Create TX
			"Profile",
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
			"JSON",
			"Profile",
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.client(
		name: "TransactionClient",
		dependencies: [
			"GatewayAPI",
			"ProfileClient",
		],
		tests: .yes(dependencies: [
			"TestUtils",
		])
	),
	.client(
		name: "UserDefaultsClient",
		dependencies: [],
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
			"Profile", // Address
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.core(
		name: "Common",
		dependencies: [
			"DesignSystem",
			"EngineToolkit",
			"Profile", // Address
			"Resources",
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.core(
		name: "SharedModels",
		dependencies: [
			"Asset",
			"Common", // FIXME: it should be the other way around — Common should depend on SharedModels and @_exported import it. However, first we need to make "EngineToolkit", etc. vend their own Model packages.
			"EngineToolkit", // FIXME: In `EngineToolkit` split out Models package
			"Profile", // FIXME: In `Profile` split out Models package
			"P2PConnection",
			"P2PModels",
		],
		tests: .yes(
			dependencies: ["TestUtils"]
		)
	),
	.core(
		name: "DesignSystem",
		dependencies: [
			.product(name: "Introspect", package: "SwiftUI-Introspect") {
				.package(url: "https://github.com/siteline/SwiftUI-Introspect", from: "0.1.4")
			},
			.product(name: "NukeUI", package: "Nuke") {
				.package(url: "https://github.com/kean/Nuke", from: "11.3.1")
			},
			"Resources",
			.product(name: "SwiftUINavigation", package: "swiftui-navigation") {
				.package(url: "https://github.com/pointfreeco/swiftui-navigation", from: "0.4.3")
			},
		],
		tests: .yes(
			dependencies: [
				"TestUtils",
			]
		)
	),
	.core(
		name: "Resources",
		dependencies: [],
		resources: [
			.process("Resources/"),
		],
		plugins: [
			.plugin(name: "SwiftGenPlugin", package: "SwiftGenPlugin") {
				.package(url: "https://github.com/SwiftGen/SwiftGenPlugin", from: "6.6.0")
			},
		],
		tests: .no
	),
	.core(
		name: "TestUtils",
		dependencies: [
			"Common",
		],
		tests: .no
	),
])

// MARK: - Modules

package.addModules([
	.module(
		name: "Profile",
		category: "Profile",
		dependencies: [
			"Cryptography",
			"EngineToolkit",
			"P2PModels",
		],
		tests: .yes(
			dependencies: [],
			resources: [
				.process("TestVectors/"),
			]
		)
	),
	.module(
		name: "ProfileView",
		category: "Profile",
		dependencies: [
			"Profile",
		],
		tests: .no
	),
	.module(
		name: "EngineToolkit",
		category: "EngineToolkit",
		dependencies: [
			"Cryptography",
			"RadixEngineToolkit",
		],
		tests: .yes(
			dependencies: [],
			resources: [
				.process("TestVectors/"),
			]
		)
	),
	.module(
		name: "P2PConnection",
		category: "RadixConnect",
		dependencies: [
			"Cryptography",
			"P2PModels",
                        "WebRTC"
		],
		tests: .yes(
			dependencies: [],
			resources: [
				.process("SignalingServerTests/TestVectors/"),
			]
		)
	),
	.module(
		name: "P2PModels",
		category: "RadixConnect",
		dependencies: [
			.product(name: "SwiftLogConsoleColors", package: "swift-log-console-colors") {
				.package(url: "https://github.com/nneuberger1/swift-log-console-colors", from: "1.0.3")
			},
		],
		tests: .yes(
			dependencies: []
		)
	),
	.module(
		name: "Cryptography",
		dependencies: [
			.product(name: "K1", package: "K1") {
				.package(url: "https://github.com/Sajjon/K1.git", from: "0.0.4")
			},
		],
		tests: .yes(
			dependencies: [],
			resources: [
				.process("MnemonicTests/TestVectors/"),
				.process("SLIP10Tests/TestVectors/"),
			]
		)
	),
	.module(
		name: "Prelude",
		dependencies: [
			.product(name: "AsyncAlgorithms", package: "swift-async-algorithms") {
				.package(url: "https://github.com/apple/swift-async-algorithms", from: "0.0.3")
			},
			.product(name: "AsyncExtensions", package: "AsyncExtensions") {
				.package(url: "https://github.com/sideeffect-io/AsyncExtensions", from: "0.5.1")
			},
			.product(name: "BigInt", package: "BigInt") {
				.package(url: "https://github.com/attaswift/BigInt", from: "5.3.0")
			},
			.product(name: "Collections", package: "swift-collections") {
				.package(url: "https://github.com/apple/swift-collections", from: "1.0.3")
			},
			.product(name: "CustomDump", package: "swift-custom-dump") {
				.package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "0.6.1")
			},
			.product(name: "Dependencies", package: "swift-dependencies") {
				.package(url: "https://github.com/pointfreeco/swift-dependencies", from: "0.1.1")
			},
			.product(name: "IdentifiedCollections", package: "swift-identified-collections") {
				.package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "0.6.0")
			},
			.product(name: "KeychainAccess", package: "KeychainAccess") {
				.package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.2")
			},
			.product(name: "LegibleError", package: "LegibleError") {
				.package(url: "https://github.com/mxcl/LegibleError", from: "1.0.6")
			},
			.product(name: "NonEmpty", package: "swift-nonempty") {
				.package(url: "https://github.com/pointfreeco/swift-nonempty", from: "0.4.0")
			},
			.product(name: "Tagged", package: "swift-tagged") {
				.package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.7.0")
			},
			.product(name: "Version", package: "Version") {
				.package(url: "https://github.com/mxcl/Version", from: "2.0.1")
			},
		],
		tests: .yes(dependencies: [])
	)
])

package.targets.append(
	.binaryTarget(
		name: "RadixEngineToolkit",
		path: "Sources/EngineToolkit/RadixEngineToolkit/RadixEngineToolkit.xcframework"
	)
)

package.targets.append(
        .binaryTarget(
            name: "WebRTC",
            path: "Sources/RadixConnect/WebRTC/WebRTC.xcframework"
        )
)

// MARK: - Extensions

extension Package {
	struct Module {
		enum Tests {
			case no
			case yes(
				nameSuffix: String = "Tests",
				dependencies: [Target.Dependency],
				resources: [Resource]? = nil
			)
		}

		let name: String
		let category: String?
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
				dependencies: dependencies + [
					.product(name: "ComposableArchitecture", package: "swift-composable-architecture") {
						.package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.49.1")
					},
					"DesignSystem",
				],
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
			isProduct: Bool = true
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
			isProduct: Bool = true
		) -> Self {
			.init(
				name: name,
				category: "Core",
				dependencies: dependencies + ["Prelude"],
				exclude: exclude,
				resources: resources,
				plugins: plugins,
				tests: tests,
				isProduct: isProduct
			)
		}

		static func module(
			name: String,
			category: String? = nil,
			dependencies: [Target.Dependency],
			exclude: [String] = [],
			resources: [Resource]? = nil,
			plugins: [Target.PluginUsage]? = nil,
			tests: Tests,
			isProduct: Bool = true
		) -> Self {
			.init(
				name: name,
				category: category,
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
		let targetPath = {
			if let category = module.category {
				return "Sources/\(category)/\(targetName)"
			} else {
				return "Sources/\(targetName)"
			}
		}()
		let dependencies = {
			if module.name == "Prelude" {
				return module.dependencies
			} else {
				return module.dependencies + ["Prelude"]
			}
		}()

		package.targets += [
			.target(
				name: targetName,
				dependencies: dependencies,
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
			let testTargetPath = {
				if let category = module.category {
					return "Tests/\(category)/\(testTargetName)"
				} else {
					return "Tests/\(testTargetName)"
				}
			}()
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

extension Target.Dependency {
	static func product(
		name: String,
		package packageName: String,
		condition: TargetDependencyCondition? = nil,
		packageDependency: () -> Package.Dependency
	) -> Self {
		package.addDependencyIfNeeded(packageDependency())
		return .product(name: name, package: packageName, condition: condition)
	}
}

extension Target.PluginUsage {
	static func plugin(name: String, package packageName: String, packageDependency: () -> Package.Dependency) -> Self {
		package.addDependencyIfNeeded(packageDependency())
		return .plugin(name: name, package: packageName)
	}
}

extension Package {
	func addDependencyIfNeeded(_ dependency: Package.Dependency) {
		if !package.dependencies.contains(where: { $0.url == dependency.url }) {
			package.dependencies.append(dependency)
		}
	}
}
