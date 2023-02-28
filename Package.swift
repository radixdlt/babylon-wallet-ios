// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Babylon",
	defaultLocalization: "en",
	platforms: [
		.macOS(.v13), // for development purposes
		.iOS(.v16),
	]
)

// MARK: - Features

package.addModules([
	.feature(
		name: "AccountDetailsFeature",
		dependencies: [
			"AccountListFeature",
			"AccountPreferencesFeature",
			"AssetsViewFeature",
			"AssetTransferFeature",
		],
		tests: .yes()
	),
	.feature(
		name: "AccountListFeature",
		dependencies: [
			"AccountPortfolio",
			"FungibleTokenListFeature",
		],
		tests: .yes()
	),
	.feature(
		name: "AccountPreferencesFeature",
		dependencies: [
			"FaucetClient",
		],
		tests: .yes()
	),
	.feature(
		name: "AggregatedValueFeature",
		dependencies: [],
		tests: .yes()
	),
	.feature(
		name: "AppFeature",
		dependencies: [
			"AccountPortfolio",
			"AppSettings",
			"MainFeature",
			"OnboardingFeature",
			"ProfileClient",
			"SplashFeature",
		],
		tests: .yes()
	),
	.feature(
		name: "AssetsViewFeature",
		dependencies: [
			"FungibleTokenListFeature",
			"NonFungibleTokenListFeature",
		],
		tests: .yes()
	),
	.feature(
		name: "AssetTransferFeature",
		dependencies: [
			"TransactionSigningFeature",
		],
		tests: .yes()
	),
	.feature(
		name: "CreateEntityFeature",
		dependencies: [
			"Cryptography",
			"GatewayAPI",
			"LocalAuthenticationClient",
			"ProfileClient",
		],
		tests: .yes()
	),
	.feature(
		name: "AuthorizedDAppsFeatures",
		dependencies: [
			"GatewayAPI",
			"ProfileClient",
		],
		tests: .no
	),
	.feature(
		name: "DappInteractionFeature",
		dependencies: [
			"CreateEntityFeature",
			"GatewayAPI",
			"P2PConnectivityClient",
			"ProfileClient",
			"TransactionSigningFeature",
		],
		tests: .yes()
	),
	.feature(
		name: "FungibleTokenDetailsFeature",
		dependencies: [],
		tests: .no
	),
	.feature(
		name: "FungibleTokenListFeature",
		dependencies: [
			"FungibleTokenDetailsFeature",
		],
		tests: .yes()
	),
	.feature(
		name: "HomeFeature",
		dependencies: [
			"AccountDetailsFeature",
			"AccountListFeature",
			"AccountPortfolio",
			"AppSettings",
			"CreateEntityFeature",
			"ProfileClient",
		],
		tests: .yes(
			dependencies: [
				"FungibleTokenListFeature",
				"NonFungibleTokenListFeature",
			]
		)
	),
	.feature(
		name: "InspectProfileFeature",
		dependencies: [
			"SecureStorageClient",
		],
		tests: .no
	),
	.feature(
		name: "MainFeature",
		dependencies: [
			"AppSettings",
			"AccountPortfolio",
			"DappInteractionFeature",
			"HomeFeature",
			"SettingsFeature",
		],
		tests: .yes()
	),
	.feature(
		name: "ManageP2PClientsFeature",
		dependencies: [
			"NewConnectionFeature",
			"P2PConnectivityClient",
		],
		tests: .yes()
	),
	.feature(
		name: "ManageGatewayAPIEndpointsFeature",
		dependencies: [
			"CreateEntityFeature",
			"GatewayAPI",
		],
		tests: .yes()
	),
	.feature(
		name: "NewConnectionFeature",
		dependencies: [
			"CameraPermissionClient",
			.product(name: "CodeScanner", package: "CodeScanner", condition: .when(platforms: [.iOS])) {
				.package(url: "https://github.com/twostraws/CodeScanner", from: "2.2.1")
			},
			"P2PConnectivityClient",
		],
		tests: .yes()
	),
	.feature(
		name: "NonFungibleTokenListFeature",
		dependencies: [],
		tests: .yes()
	),
	.feature(
		name: "OnboardingFeature",
		dependencies: [
			"CreateEntityFeature",
			"ProfileClient",
		],
		tests: .yes()
	),
	.feature(
		name: "PersonasFeature",
		dependencies: [
			"CreateEntityFeature",
		],
		tests: .yes()
	),
	.feature(
		name: "SettingsFeature",
		dependencies: [
			"AuthorizedDAppsFeatures",
			"GatewayAPI",
			"ManageP2PClientsFeature",
			"ManageGatewayAPIEndpointsFeature",
			"PersonasFeature",
			"P2PConnectivityClient", // deleting connections when wallet is deleted
			"InspectProfileFeature",
		],
		tests: .yes()
	),
	.feature(
		name: "SplashFeature",
		dependencies: [
			"LocalAuthenticationClient",
			"ProfileClient",
		],
		tests: .yes()
	),
	.feature(
		name: "TransactionSigningFeature",
		dependencies: [
			"GatewayAPI",
			"TransactionClient",
		],
		tests: .yes()
	),
])

// MARK: - Clients

package.addModules([
	.client(
		name: "AccountsClient",
		dependencies: [
			"ProfileStore",
		],
		tests: .yes()
	),
	.client(
		name: "AccountPortfolio",
		dependencies: [
			"AppSettings",
			"EngineToolkitClient",
			"GatewayAPI",
			"ProfileClient",
		],
		tests: .yes()
	),
	.client(
		name: "AppSettings",
		dependencies: [],
		tests: .yes()
	),
	.client(
		name: "CameraPermissionClient",
		dependencies: [],
		tests: .no
	),
	.client(
		name: "EngineToolkitClient",
		dependencies: [
			"Cryptography",
			"EngineToolkit",
			"Profile",
		],
		tests: .yes()
	),
	.client(
		name: "FaucetClient",
		dependencies: [
			"EngineToolkitClient",
			"GatewayAPI",
			"ProfileClient",
			"TransactionClient",
		],
		tests: .yes()
	),
	.client(
		name: "GatewayAPI",
		dependencies: [
			.product(name: "AnyCodable", package: "AnyCodable") {
				// Unfortunate GatewayAPI OpenAPI Generated Model dependency :/
				.package(url: "https://github.com/Flight-School/AnyCodable", from: "0.6.6")
			},
			"Cryptography",
			"ProfileClient",
		],
		exclude: [
			"CodeGen/Input/",
		],
		tests: .yes()
	),
	.client(
		name: "LocalAuthenticationClient",
		dependencies: [],
		tests: .yes()
	),
	.client(
		name: "P2PConnectivityClient",
		dependencies: [
			"P2PConnection",
			"ProfileClient",
		],
		tests: .yes()
	),
	.client(
		name: "ProfileClient",
		dependencies: [
			"Profile",
			"Cryptography",
			"UseFactorSourceClient",
		],
		tests: .no
	),
	.client(
		name: "ProfileClientLive",
		dependencies: [
			"ProfileClient",
			"EngineToolkitClient",
			"SecureStorageClient",
		],
		tests: .yes()
	),
	.client(
		name: "ProfileStore",
		dependencies: [
			"Profile",
			"SecureStorageClient",
		],
		tests: .yes()
	),
	.client(
		name: "SecureStorageClient",
		dependencies: [
			"Profile",
			"Cryptography",
			"LocalAuthenticationClient",
			"Resources", // L10n for keychain auth prompts
		],
		tests: .yes()
	),
	.client(
		name: "TransactionClient",
		dependencies: [
			"EngineToolkitClient",
			"GatewayAPI",
			"ProfileClient",
			"AccountPortfolio",
			"UseFactorSourceClient",
			"SecureStorageClient",
		],
		tests: .yes()
	),
	.client(
		name: "UseFactorSourceClient",
		dependencies: [
			"Profile",
			"Cryptography",
			"SecureStorageClient",
		],
		tests: .no
	),
])

// MARK: - Core

package.addModules([
	.core(
		name: "FeaturePrelude",
		dependencies: [
			.product(name: "ComposableArchitecture", package: "swift-composable-architecture") {
				.package(url: "https://github.com/davdroman/swift-composable-architecture", branch: "navigation-relay")
			},
			"DesignSystem",
			"Resources",
			"SharedModels",
		],
		tests: .no
	),
	.core(
		name: "ClientPrelude",
		dependencies: [
			"Resources", // TODO: should be L10n on its own. We'll split L10n into its own module at some point.
			"SharedModels",
		],
		tests: .no
	),
	.core(
		name: "DesignSystem",
		dependencies: [
			.product(name: "Introspect", package: "SwiftUI-Introspect") {
				.package(url: "https://github.com/siteline/SwiftUI-Introspect", from: "0.1.4")
			},
			.product(name: "NavigationTransitions", package: "swiftui-navigation-transitions", condition: .when(platforms: [.iOS])) {
				.package(url: "https://github.com/davdroman/swiftui-navigation-transitions", from: "0.1.0")
			},
			.product(name: "NukeUI", package: "Nuke") {
				.package(url: "https://github.com/kean/Nuke", from: "11.3.1")
			},
			"Resources",
			.product(name: "SwiftUINavigation", package: "swiftui-navigation") {
				.package(url: "https://github.com/pointfreeco/swiftui-navigation", from: "0.4.3")
			},
		],
		tests: .yes()
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
		name: "SharedTestingModels",
		dependencies: [
			"SharedModels",
		],
		resources: [
			.process("TestVectorsSharedByMultipleTargets/"),
		],
		tests: .no
	),
	.core(
		name: "SharedModels",
		dependencies: [
			"EngineToolkitModels",
			"Profile",
			"P2PConnection", // FIXME: remove dependency on this, rely only on P2PModels
			"P2PModels",
		],
		exclude: [
			"P2P/Codable/README.md",
			"P2P/Application/README.md",
		],
		tests: .yes()
	),
])

// MARK: - Modules

package.addModules([
	.module(
		name: "Profile",
		dependencies: [
			"Cryptography",
			"EngineToolkit", // address derivation
			"P2PModels",
		],
		tests: .yes(
			dependencies: [
				"SharedTestingModels",
			]
		)
	),
	.module(
		name: "EngineToolkit",
		category: .engineToolkit,
		dependencies: [
			"Cryptography",
			"EngineToolkitModels",
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
		name: "EngineToolkitModels",
		category: .engineToolkit,
		dependencies: [
			"Cryptography",
		],
		tests: .no
	),
	.module(
		name: "P2PConnection",
		category: .radixConnect,
		dependencies: [
			"Cryptography",
			"P2PModels",
			.product(name: "WebRTC", package: "WebRTC") {
				.package(url: "https://github.com/stasel/WebRTC", from: "109.0.1")
			},
		],
		exclude: [
			"ChunkingTransport/README.md",
		],
		tests: .yes(
			dependencies: [
				"SharedTestingModels",
			],
			resources: [
				.process("SignalingServerTests/TestVectors/"),
			]
		)
	),
	.module(
		name: "P2PModels",
		category: .radixConnect,
		dependencies: [
			"Cryptography",
		],
		tests: .yes()
	),
	.module(
		name: "Cryptography",
		dependencies: [
			.product(name: "K1", package: "K1") {
				.package(url: "https://github.com/Sajjon/K1.git", from: "0.0.4")
			},
		],
		exclude: [
			"Mnemonic/README.md",
			"SLIP10/README.md",
		],
		tests: .yes(
			dependencies: [
				"SharedTestingModels",
			],
			resources: [
				.process("MnemonicTests/TestVectors/"),
				.process("SLIP10Tests/TestVectors/"),
			]
		)
	),
	.module(
		name: "TestingPrelude",
		category: .testing,
		dependencies: [
			.product(name: "JSONTesting", package: "swift-json-testing") {
				.package(url: "https://github.com/davdroman/swift-json-testing", from: "0.1.0")
			},
		],
		tests: .no
	),
	.module(
		name: "FeatureTestingPrelude",
		category: .testing,
		dependencies: [
			"FeaturePrelude", "TestingPrelude", "SharedTestingModels",
		],
		tests: .no
	),
	.module(
		name: "ClientTestingPrelude",
		category: .testing,
		dependencies: [
			"ClientPrelude", "TestingPrelude", "SharedTestingModels",
		],
		tests: .no
	),
	.module(
		name: "Prelude",
		remoteDependencies: [
			.package(url: "https://github.com/apple/swift-collections", branch: "main"), // TODO: peg to specific version once main is tagged
		],
		dependencies: [
			.product(name: "Algorithms", package: "swift-algorithms") {
				.package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0")
			},
			.product(name: "AsyncAlgorithms", package: "swift-async-algorithms") {
				.package(url: "https://github.com/apple/swift-async-algorithms", from: "0.0.3")
			},
			.product(name: "AsyncExtensions", package: "AsyncExtensions") {
				.package(url: "https://github.com/sideeffect-io/AsyncExtensions", from: "0.5.1")
			},
			.product(name: "BigInt", package: "BigInt") {
				.package(url: "https://github.com/attaswift/BigInt", from: "5.3.0")
			},
			.product(name: "BigDecimal", package: "BigDecimal") {
				.package(url: "https://github.com/Zollerboy1/BigDecimal.git", from: "1.0.0")
			},

			.product(name: "BitCollections", package: "swift-collections"),
			.product(name: "Collections", package: "swift-collections"),

			.product(name: "CustomDump", package: "swift-custom-dump") {
				.package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "0.6.1")
			},
			.product(name: "Dependencies", package: "swift-dependencies") {
				.package(url: "https://github.com/pointfreeco/swift-dependencies", from: "0.1.1")
			},
			.product(name: "DependenciesAdditions", package: "swift-dependencies-additions") {
				.package(url: "https://github.com/tgrapperon/swift-dependencies-additions", from: "0.2.0")
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
			.product(name: "SwiftLogConsoleColors", package: "swift-log-console-colors") {
				.package(url: "https://github.com/nneuberger1/swift-log-console-colors", from: "1.0.3")
			},
			.product(name: "Tagged", package: "swift-tagged") {
				.package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.7.0")
			},
			.product(name: "CollectionConcurrencyKit", package: "CollectionConcurrencyKit") {
				.package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git", from: "0.1.0")
			},
		],
		tests: .yes(dependencies: [])
	),
])

package.targets.append(
	.binaryTarget(
		name: "RadixEngineToolkit",
		path: "Sources/EngineToolkit/RadixEngineToolkit/RadixEngineToolkit.xcframework"
	)
)

// MARK: - Unit Tests

package.addModules([
	.module(name: "Unit Tests", dependencies: [], tests: .no),
])

// MARK: - Extensions

extension Package {
	struct Module {
		enum Tests {
			case no
			case yes(
				nameSuffix: String = "Tests",
				dependencies: [Target.Dependency] = [],
				resources: [Resource]? = nil
			)
		}

		enum Category {
			case client
			case feature
			case core
			case module(name: String)
			static let testing: Self = .module(name: "Testing")
			static let engineToolkit: Self = .module(name: "EngineToolkit")
			static let radixConnect: Self = .module(name: "RadixConnect")
			var pathComponent: String {
				switch self {
				case .client: return "Clients"
				case .feature: return "Features"
				case .core: return "Core"
				case let .module(name):
					return name
				}
			}
		}

		let name: String
		let category: Category?
		let remoteDependencies: [Package.Dependency]?
		let dependencies: [Target.Dependency]
		let exclude: [String]
		let resources: [Resource]?
		let plugins: [Target.PluginUsage]?
		let tests: Tests
		let isProduct: Bool

		static func feature(
			name: String,
			remoteDependencies: [Package.Dependency]? = nil,
			dependencies: [Target.Dependency],
			exclude: [String] = [],
			resources: [Resource]? = nil,
			plugins: [Target.PluginUsage]? = nil,
			tests: Tests,
			isProduct: Bool = true
		) -> Self {
			.init(
				name: name,
				category: .feature,
				remoteDependencies: remoteDependencies,
				dependencies: dependencies + ["FeaturePrelude"],
				exclude: exclude,
				resources: resources,
				plugins: plugins,
				tests: tests,
				isProduct: isProduct
			)
		}

		static func client(
			name: String,
			remoteDependencies: [Package.Dependency]? = nil,
			dependencies: [Target.Dependency],
			exclude: [String] = [],
			resources: [Resource]? = nil,
			plugins: [Target.PluginUsage]? = nil,
			tests: Tests,
			isProduct: Bool = true
		) -> Self {
			.init(
				name: name,
				category: .client,
				remoteDependencies: remoteDependencies,
				dependencies: dependencies + ["ClientPrelude"],
				exclude: exclude,
				resources: resources,
				plugins: plugins,
				tests: tests,
				isProduct: isProduct
			)
		}

		static func core(
			name: String,
			remoteDependencies: [Package.Dependency]? = nil,
			dependencies: [Target.Dependency],
			exclude: [String] = [],
			resources: [Resource]? = nil,
			plugins: [Target.PluginUsage]? = nil,
			tests: Tests,
			isProduct: Bool = true
		) -> Self {
			.init(
				name: name,
				category: .core,
				remoteDependencies: remoteDependencies,
				dependencies: dependencies,
				exclude: exclude,
				resources: resources,
				plugins: plugins,
				tests: tests,
				isProduct: isProduct
			)
		}

		static func module(
			name: String,
			category: Category? = nil,
			remoteDependencies: [Package.Dependency]? = nil,
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
				remoteDependencies: remoteDependencies,
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
		if let remoteDependencies = module.remoteDependencies {
			package.dependencies.append(contentsOf: remoteDependencies)
		}

		let targetName = module.name
		let targetPath = {
			if let category = module.category {
				return "Sources/\(category.pathComponent)/\(targetName)"
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
		case let .yes(nameSuffix, customAdditionalTestDependencies, resources):
			let testTargetName = targetName + nameSuffix
			let testTargetPath = {
				if let category = module.category {
					return "Tests/\(category.pathComponent)/\(testTargetName)"
				} else {
					return "Tests/\(testTargetName)"
				}
			}()

			let testTargetDependencies = [.target(name: targetName)] + customAdditionalTestDependencies + {
				switch module.category {
				case .some(.feature):
					return ["FeatureTestingPrelude"]
				case .some(.client):
					return ["ClientTestingPrelude"]
				case .some(.core), .some(.module), .none:
					return ["TestingPrelude"]
				}
			}()

			package.targets += [
				.testTarget(
					name: testTargetName,
					dependencies: testTargetDependencies,
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
		if !package.dependencies.contains(where: { $0.id == dependency.id }) {
			package.dependencies.append(dependency)
		}
	}
}

extension Package.Dependency {
	var id: String {
		switch kind {
		case let .fileSystem(_, path):
			return path
		case let .registry(id, _):
			return id
		case let .sourceControl(_, url, _):
			return url
		@unknown default:
			fatalError()
		}
	}
}
