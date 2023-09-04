// swift-tools-version: 5.8
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
			"AccountPreferencesFeature",
			"AssetTransferFeature",
			"AccountPortfoliosClient",
			"AssetsFeature",
			"ImportMnemonicFeature",
			"ProfileBackupsFeature",
			"BackupsClient",
		],
		tests: .yes()
	),
	.feature(
		name: "AccountListFeature",
		dependencies: [
			"AccountPortfoliosClient",
			"FactorSourcesClient", // check if `device` or `ledger` controlled for security prompting
			"AccountDetailsFeature", // "shield buttons"
		],
		tests: .no
	),
	.feature(
		name: "AccountPreferencesFeature",
		dependencies: [
			"FaucetClient",
			"AccountPortfoliosClient",
			"CreateAuthKeyFeature",
			"ShowQRFeature",
			"OverlayWindowClient",
			"OnLedgerEntitiesClient",
		],
		tests: .yes()
	),
	.feature(
		name: "AddLedgerFactorSourceFeature",
		featureSuffixDroppedFromFolderName: true,
		dependencies: [
			"FactorSourcesClient",
			"RadixConnectClient",
			"LedgerHardwareWalletClient",
			"NewConnectionFeature",
		],
		tests: .no
	),
	.feature(
		name: "ManageTrustedContactFactorSourceFeature",
		featureSuffixDroppedFromFolderName: true,
		dependencies: [
			"FactorSourcesClient",
			"ScanQRFeature",
		],
		tests: .no
	),
	.feature(
		name: "AnswerSecurityQuestionsFeature",
		featureSuffixDroppedFromFolderName: true,
		dependencies: [
			"Profile",
			"MnemonicClient",
			"FactorSourcesClient",
		],
		tests: .no
	),
	.feature(
		name: "AppFeature",
		dependencies: [
			"AppPreferencesClient",
			"MainFeature",
			"OnboardingFeature",
			"OverlayWindowClient",
			"CreateAccountFeature",
			"NetworkSwitchingClient",
			"GatewayAPI",
			"SplashFeature",
		],
		tests: .yes()
	),
	.feature(
		name: "AssetTransferFeature",
		dependencies: [
			"ScanQRFeature",
			"ChooseAccountsFeature",
			"AssetsFeature",
			"DappInteractionClient",
			"EngineKit",
		],
		tests: .yes()
	),
	.feature(
		name: "AssetsFeature",
		dependencies: [
			"AccountPortfoliosClient",
		],
		tests: .no
	),
	.feature(
		name: "AuthorizedDAppsFeature",
		dependencies: [
			"AuthorizedDappsClient",
			"CacheClient",
			"EditPersonaFeature",
			"PersonasFeature",
			"GatewayAPI",
		],
		tests: .no
	),
	.feature(
		name: "ChooseAccountsFeature",
		featureSuffixDroppedFromFolderName: true,
		dependencies: [
			"AccountsClient",
			"CreateAccountFeature",
		],
		tests: .no
	),
	.feature(
		name: "CreateAuthKeyFeature",
		featureSuffixDroppedFromFolderName: true,
		dependencies: [
			"TransactionReviewFeature",
			"DerivePublicKeysFeature",
			"ROLAClient",
		],
		tests: .no
	),
	.feature(
		name: "CreateAccountFeature",
		featureSuffixDroppedFromFolderName: true,
		dependencies: [
			"AddLedgerFactorSourceFeature",
			"AccountsClient",
			"LedgerHardwareDevicesFeature",
			"Cryptography",
			"DerivePublicKeysFeature",
			"FactorSourcesClient",
			"GatewayAPI",
			"LedgerHardwareWalletClient",
		],
		tests: .no
	),
	.feature(
		name: "CreatePersonaFeature",
		featureSuffixDroppedFromFolderName: true,
		dependencies: [
			"Cryptography",
			"FactorSourcesClient",
			"GatewayAPI",
			"PersonasClient",
			"DerivePublicKeysFeature",
		],
		tests: .no
	),
	.feature(
		name: "DappInteractionFeature",
		dependencies: [
			"AppPreferencesClient",
			"AuthorizedDappsClient",
			"CreateAccountFeature",
			"CreatePersonaFeature",
			"CacheClient",
			"ChooseAccountsFeature",
			"EditPersonaFeature",
			"GatewayAPI",
			"GatewaysClient", // get current network
			"RadixConnectClient",
			"PersonasClient",
			"ROLAClient",
			"TransactionReviewFeature",
			"SigningFeature",
			"DappInteractionClient",
		],
		tests: .yes()
	),
	.feature(
		name: "DebugInspectProfileFeature",
		featureSuffixDroppedFromFolderName: true,
		dependencies: [
			"Profile",
			"RadixConnectModels",
		],
		tests: .no
	),
	.feature(
		name: "DerivePublicKeysFeature",
		featureSuffixDroppedFromFolderName: true,
		dependencies: [
			"AccountsClient",
			"DeviceFactorSourceClient",
			"FactorSourcesClient",
			"LedgerHardwareWalletClient",
			"PersonasClient",
		],
		tests: .no
	),
	.feature(
		name: "DisplayEntitiesControlledByMnemonicFeature",
		featureSuffixDroppedFromFolderName: true,
		dependencies: [
		],
		tests: .no
	),
	.feature(
		name: "EditPersonaFeature",
		dependencies: [
			"PersonasClient",
			"Profile",
		],
		tests: .no
	),
	.feature(
		name: "FeaturesPreviewerFeature",
		featureSuffixDroppedFromFolderName: true,
		dependencies: [],
		tests: .no
	),
	.feature(
		name: "GatewaySettingsFeature",
		dependencies: [
			"CreateAccountFeature",
			"GatewaysClient",
			"NetworkSwitchingClient",
		],
		tests: .yes()
	),
	.feature(
		name: "HomeFeature",
		dependencies: [
			"AccountDetailsFeature",
			"AccountListFeature",
			"AccountPortfoliosClient",
			"AccountsClient",
			"AppPreferencesClient",
			"CreateAccountFeature",
			"ImportMnemonicFeature",
			"ProfileBackupsFeature", // actually only ImportMnemonicsFlowCoodinator, might split it out in future
		],
		tests: .yes()
	),
	.feature(
		name: "ImportMnemonicFeature",
		featureSuffixDroppedFromFolderName: true,
		dependencies: [
			"FactorSourcesClient", // saves into profile, if specified
			"MnemonicClient",
			"OverlayWindowClient",
			.product(name: "ScreenshotPreventing", package: "ScreenshotPreventing-iOS", condition: .when(platforms: [.iOS])) {
				.package(url: "https://github.com/Sajjon/ScreenshotPreventing-iOS.git", from: "0.0.1")
			},
		],
		tests: .no
	),
	.feature(
		name: "ImportOlympiaLedgerAccountsAndFactorSourcesFeature",
		featureSuffixDroppedFromFolderName: true,
		dependencies: [
			"FactorSourcesClient",
			"RadixConnectClient",
			"ImportLegacyWalletClient",
			"DerivePublicKeysFeature",
			"LedgerHardwareDevicesFeature",
		],
		tests: .no
	),
	.feature(
		name: "LedgerHardwareDevicesFeature",
		featureSuffixDroppedFromFolderName: true,
		dependencies: [
			"AddLedgerFactorSourceFeature",
		],
		tests: .no
	),
	.feature(
		name: "MainFeature",
		dependencies: [
			"AppPreferencesClient",
			"DappInteractionFeature",
			"HomeFeature",
			"SettingsFeature",
		],
		tests: .yes()
	),
	.feature(
		name: "ManageSecurityStructureFeature",
		featureSuffixDroppedFromFolderName: true,
		dependencies: [
			"Profile",
			"AnswerSecurityQuestionsFeature",
			"ManageTrustedContactFactorSourceFeature",
			"LedgerHardwareDevicesFeature",
			"ImportMnemonicFeature", // Add `offDeviceMnemonic`
			"AppPreferencesClient", // Save SecurityStructureConfig
		],
		tests: .no
	),
	.feature(
		name: "NewConnectionFeature",
		dependencies: [
			"RadixConnectClient",
			"ScanQRFeature",
		],
		tests: .yes()
	),
	.feature(
		name: "OnboardingFeature",
		dependencies: [
			"CreateAccountFeature",
			"OnboardingClient",
			"ProfileBackupsFeature",
		],
		tests: .yes()
	),
	.feature(
		name: "P2PLinksFeature",
		dependencies: [
			"NewConnectionFeature",
			"RadixConnectClient",
		],
		tests: .yes()
	),
	.feature(
		name: "PersonasFeature",
		dependencies: [
			"PersonaDetailsFeature",
			"CreatePersonaFeature",
			"PersonasClient",
		],
		tests: .yes()
	),
	.feature(
		name: "PersonaDetailsFeature",
		dependencies: [
			"AuthorizedDappsClient",
			"EditPersonaFeature",
			"CreateAuthKeyFeature",
			"GatewayAPI",
		],
		tests: .no
	),
	.feature(
		name: "ProfileBackupsFeature",
		dependencies: [
			"AppPreferencesClient",
			"BackupsClient",
			"CacheClient",
			"DeviceFactorSourceClient",
			"DisplayEntitiesControlledByMnemonicFeature",
			"ImportMnemonicFeature",
			"OverlayWindowClient",
			"RadixConnectClient",
		],
		tests: .no
	),
	.feature(
		name: "ScanQRFeature",
		featureSuffixDroppedFromFolderName: true,
		dependencies: [
			"CameraPermissionClient",
			.product(
				name: "CodeScanner",
				package: "CodeScanner",
				condition: .when(platforms: [.iOS])
			) {
				.package(url: "https://github.com/twostraws/CodeScanner", from: "2.2.1")
			},
		],
		tests: .no
	),
	.feature(
		name: "SecurityStructureConfigurationListFeature",
		featureSuffixDroppedFromFolderName: true,
		dependencies: [
			"AppPreferencesClient",
			"ManageSecurityStructureFeature",
		],
		tests: .no
	),
	.feature(
		name: "SettingsFeature",
		dependencies: [
			"AccountsClient",
			"AddLedgerFactorSourceFeature",
			"AppPreferencesClient",
			"AuthorizedDAppsFeature",
			"CacheClient",
			"DebugInspectProfileFeature",
			"DeviceFactorSourceClient",
			"DisplayEntitiesControlledByMnemonicFeature",
			"EditPersonaFeature",
			"EngineKit",
			"FactorSourcesClient", // Check if user has any ledgers
			"FaucetClient", //  EpochForWhenLastUsedByAccountAddress
			"GatewayAPI",
			"GatewaySettingsFeature",
			"ImportMnemonicFeature",
			"ImportOlympiaLedgerAccountsAndFactorSourcesFeature",
			"ImportLegacyWalletClient",
			"P2PLinksFeature",
			"PersonasFeature",
			"RadixConnectClient",
			"ProfileBackupsFeature",
			"ScanQRFeature",
			"SecurityStructureConfigurationListFeature",
		],
		tests: .yes()
	),
	.feature(
		name: "ShowQRFeature",
		dependencies: [],
		tests: .no
	),
	.feature(
		name: "SigningFeature",
		featureSuffixDroppedFromFolderName: true,
		dependencies: [
			"AppPreferencesClient",
			"FactorSourcesClient",
			"LedgerHardwareWalletClient",
			"Profile",
			"TransactionClient",
			"DeviceFactorSourceClient",
			"ROLAClient",
			"EngineKit",
		],
		tests: .no
	),
	.feature(
		name: "SplashFeature",
		dependencies: [
			"DeviceFactorSourceClient",
			"LocalAuthenticationClient",
			"OnboardingClient",
			"GatewayAPI",
		],
		tests: .yes()
	),
	.feature(
		name: "TransactionReviewFeature",
		dependencies: [
			"AssetsFeature",
			"AuthorizedDappsClient",
			"GatewayAPI",
			"OnLedgerEntitiesClient",
			"TransactionClient",
			"SigningFeature",
			"SubmitTransactionClient",
			"Cryptography",
		],
		tests: .yes()
	),

])

// MARK: - Clients
package.addModules([
	.client(
		name: "AccountsClient",
		dependencies: [
			"Profile",
		],
		tests: .no
	),
	.client(
		name: "AccountsClientLive",
		dependencies: [
			"AccountsClient",
			"ProfileStore",
		],
		tests: .yes()
	),
	.client(
		name: "AccountPortfoliosClient",
		dependencies: [
			"GatewayAPI",
			"CacheClient",
			"EngineKit",
		],
		tests: .yes()
	),
	.client(
		name: "OnLedgerEntitiesClient",
		dependencies: [
			"GatewayAPI",
			"CacheClient",
			"EngineKit",
		],
		tests: .no
	),
	.client(
		name: "AppPreferencesClient",
		dependencies: [
			"Profile",
		],
		tests: .no
	),
	.client(
		name: "AppPreferencesClientLive",
		dependencies: [
			"AppPreferencesClient",
			"ProfileStore",
			"SecureStorageClient",
		],
		tests: .yes()
	),

	.client(
		name: "AuthorizedDappsClient",
		dependencies: [
			"Profile",
		],
		tests: .no
	),
	.client(
		name: "AuthorizedDappsClientLive",
		dependencies: [
			"AuthorizedDappsClient",
			"ProfileStore",
		],
		tests: .yes()
	),

	.client(
		name: "BackupsClient",
		dependencies: [
			"Profile",
			"Cryptography",
		],
		tests: .no
	),
	.client(
		name: "BackupsClientLive",
		dependencies: [
			"BackupsClient",
			"ProfileStore",
		],
		tests: .no
	),

	.client(
		name: "CacheClient",
		dependencies: [
			"DiskPersistenceClient",
		],
		tests: .yes()
	),
	.client(
		name: "CameraPermissionClient",
		dependencies: [],
		tests: .no
	),
	.client(
		name: "DappInteractionClient",
		dependencies: [],
		tests: .no
	),
	.client(
		name: "DappInteractionClientLive",
		dependencies: [
			"RadixConnectClient",
			"GatewaysClient",
			"AppPreferencesClient",
			"DappInteractionClient",
		],
		tests: .no
	),
	.client(
		name: "DiskPersistenceClient",
		dependencies: [],
		tests: .yes()
	),
	.client(
		name: "FactorSourcesClient",
		dependencies: [
			"Profile",
		],
		tests: .no
	),
	.client(
		name: "FactorSourcesClientLive",
		dependencies: [
			"FactorSourcesClient",
			"ProfileStore",
		],
		tests: .yes()
	),

	.client(
		name: "FaucetClient",
		dependencies: [
			"DeviceFactorSourceClient",
			"GatewayAPI",
			"GatewaysClient", // getCurrentNetworkID
			"SubmitTransactionClient",
			"TransactionClient",
			"EngineKit",
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
			"GatewaysClient",
		],
		exclude: [
			"CodeGen/Input/",
		],
		tests: .yes(),
		disableConcurrencyChecks: true
	),

	.client(
		name: "GatewaysClient",
		dependencies: [
			"Profile",
		],
		tests: .no
	),
	.client(
		name: "GatewaysClientLive",
		dependencies: [
			"GatewaysClient",
			"AppPreferencesClient",
			"ProfileStore",
		],
		tests: .yes()
	),
	.client(
		name: "ImportLegacyWalletClient",
		dependencies: [
			"AccountsClient",
			"LedgerHardwareWalletClient",
			"Profile", // Olympia models
			"EngineKit",
		],
		tests: .yes(
			resources: [
				.process("TestVectors/"),
			]
		)
	),
	.client(
		name: "LedgerHardwareWalletClient",
		dependencies: [
			"ROLAClient", // calc expected hashed message for signAuth for validation
			"RadixConnectClient",
			"FactorSourcesClient", // FIXME: move models to lower level package
		],
		tests: .no
	),
	.client(
		name: "LocalAuthenticationClient",
		dependencies: [],
		tests: .yes()
	),

	.client(
		name: "MnemonicClient",
		dependencies: ["Cryptography"],
		tests: .no
	),

	.client(
		name: "NetworkSwitchingClient",
		dependencies: [
			"AccountsClient",
			"CacheClient",
			"GatewayAPI",
			"GatewaysClient",
			"ProfileStore",
		],
		tests: .no
	),
	.client(
		name: "OverlayWindowClient",
		dependencies: [
			"DesignSystem", // please forgive me... only access to colors. I will be judge for all time for this!
		],
		tests: .no
	),
	.client(
		name: "OverlayWindowClientLive",
		dependencies: [
			"OverlayWindowClient",
		],
		tests: .no
	),
	.client(
		name: "OnboardingClientLive",
		dependencies: [
			"OnboardingClient",
			"ProfileStore",
		],
		tests: .yes()
	),

	.client(
		name: "OnboardingClient",
		dependencies: [
			"Profile",
			"Cryptography",
		],
		tests: .no
	),

	.client(
		name: "P2PLinksClient",
		dependencies: [
			"Profile",
		],
		tests: .no
	),
	.client(
		name: "P2PLinksClientLive",
		dependencies: [
			"ProfileStore",
			"P2PLinksClient",
			"AppPreferencesClient",
		],
		tests: .yes()
	),
	.client(
		name: "QRGeneratorClient",
		dependencies: [],
		tests: .no
	),
	.client(
		name: "QRGeneratorClientLive",
		dependencies: [
			"QRGeneratorClient",
		],
		tests: .no
	),
	.client(
		name: "RadixConnectClient",
		dependencies: [
			"RadixConnect",
			"P2PLinksClient",
			.product(name: "ComposableArchitecture", package: "swift-composable-architecture"), // actually just CasePaths
		],
		tests: .yes()
	),
	.client(
		name: "PersonasClient",
		dependencies: [
			"Profile",
		],
		tests: .no
	),
	.client(
		name: "PersonasClientLive",
		dependencies: [
			"PersonasClient",
			"ProfileStore",
		],
		tests: .yes()
	),
	.client(
		name: "ProfileStore",
		dependencies: [
			"Profile",
			"SecureStorageClient",
			"MnemonicClient",
			"DeviceFactorSourceClient", // FIXME: break out to `BaseProfileClient` or similar
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
		name: "ROLAClient",
		dependencies: [
			"AccountsClient",
			"GatewayAPI",
			"CacheClient",
			"DeviceFactorSourceClient",
			"EngineKit",
		],
		tests: .yes(
			dependencies: [],
			resources: [
				.process("TestVectors/"),
			]
		)
	),
	.client(
		name: "SubmitTransactionClient",
		dependencies: [
			"GatewayAPI",
			"TransactionClient",
			"EngineKit",
		],
		tests: .no
	),
	.client(
		name: "TransactionClient",
		dependencies: [
			"AccountsClient",
			"AccountPortfoliosClient",
			"FactorSourcesClient",
			"GatewayAPI",
			"PersonasClient",
			"EngineKit",
		],
		tests: .yes()
	),
	.client(
		name: "DeviceFactorSourceClient",
		dependencies: [
			"AccountsClient",
			"Cryptography",
			"FactorSourcesClient",
			"Profile",
			"PersonasClient",
			"SecureStorageClient",
		],
		tests: .no
	),
	.client(
		name: "URLFormatterClient",
		dependencies: [],
		tests: .no
	),
	.client(
		name: "URLFormatterClientLive",
		dependencies: [
			"URLFormatterClient",
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
				.package(url: "https://github.com/radixdlt/swift-composable-architecture", branch: "full-scope")
			},
			"DesignSystem",
			"Resources",
			"SharedModels",
		],
		tests: .yes()
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
			"GatewaysClient",
			"URLFormatterClient",
			"QRGeneratorClient",
			.product(name: "Introspect", package: "SwiftUI-Introspect") {
				.package(url: "https://github.com/siteline/SwiftUI-Introspect", from: "0.1.4")
			},
			.product(name: "NavigationTransitions", package: "swiftui-navigation-transitions", condition: .when(platforms: [.iOS])) {
				.package(url: "https://github.com/davdroman/swiftui-navigation-transitions", exact: "0.9.0")
			},
			.product(name: "NukeUI", package: "Nuke") {
				.package(url: "https://github.com/kean/Nuke", from: "11.3.1")
			},
			"Resources",
			.product(name: "SwiftUINavigation", package: "swiftui-navigation") {
				.package(url: "https://github.com/pointfreeco/swiftui-navigation", from: "0.7.1")
			},
			.product(name: "TextBuilder", package: "TextBuilder") {
				.package(url: "https://github.com/davdroman/TextBuilder", from: "2.2.0")
			},
			.product(
				name: "JSONPreview",
				package: "JSONPreview",
				condition: .when(platforms: [.iOS])
			) {
				.package(url: "https://github.com/rakuyoMo/JSONPreview.git", from: "2.0.0")
			},
		],
		tests: .no
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
			"RadixConnectModels",
			"Profile",
		],
		exclude: [
			"P2P/Dapp/README.md",
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
			"EngineKit",
			"RadixConnectModels",
			"Resources",
			.product(name: "ComposableArchitecture", package: "swift-composable-architecture"), // actually just CasePaths
		],
		tests: .yes(
			dependencies: [
				"SharedTestingModels",
			],
			resources: [
				.process("TestVectors/"),
			]
		)
	),
	.module(
		name: "RadixConnectModels",
		category: .radixConnect,
		dependencies: [
			"Cryptography",
		],
		tests: .yes()
	),
	.module(
		name: "RadixConnect",
		category: .radixConnect,
		dependencies: [
			"RadixConnectModels",
			"SharedModels",
			"GatewaysClient",
			.product(name: "WebRTC", package: "WebRTC") {
				.package(url: "https://github.com/stasel/WebRTC", from: "116.0.0")
			},
		],
		tests: .yes()
	),
	.module(
		name: "Cryptography",
		dependencies: [
			.product(name: "K1", package: "K1") {
				.package(url: "https://github.com/Sajjon/K1.git", exact: "0.3.8")
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
		name: "EngineKit",
		dependencies: [
			"Cryptography",
			.product(name: "EngineToolkit", package: "swift-engine-toolkit") {
				.package(url: "https://github.com/radixdlt/swift-engine-toolkit", branch: "release/rcnet-v3")
			},
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

			.product(name: "Builders", package: "swift-builders") {
				.package(url: "https://github.com/davdroman/swift-builders", from: "0.4.0")
			},

			.product(name: "Collections", package: "swift-collections"),

			.product(name: "CollectionConcurrencyKit", package: "CollectionConcurrencyKit") {
				.package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git", from: "0.1.0")
			},
			.product(name: "CustomDump", package: "swift-custom-dump") {
				.package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "0.9.1")
			},
			.product(name: "Dependencies", package: "swift-dependencies") {
				.package(url: "https://github.com/pointfreeco/swift-dependencies", from: "0.2.0")
			},
			.product(name: "DependenciesAdditions", package: "swift-dependencies-additions") {
				.package(url: "https://github.com/tgrapperon/swift-dependencies-additions", from: "0.3.0")
			},
			.product(name: "Either", package: "swift-either") {
				.package(url: "https://github.com/pointfreeco/swift-either", branch: "main")
			},
			.product(name: "IdentifiedCollections", package: "swift-identified-collections") {
				.package(url: "https://github.com/pointfreeco/swift-identified-collections", exact: "0.7.0")
			},
			.product(name: "KeychainAccess", package: "KeychainAccess") {
				.package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.2")
			},
			.product(name: "LegibleError", package: "LegibleError") {
				.package(url: "https://github.com/mxcl/LegibleError", from: "1.0.6")
			},
			.product(name: "NonEmpty", package: "swift-nonempty") {
				.package(url: "https://github.com/pointfreeco/swift-nonempty", exact: "0.4.0")
			},
			.product(name: "SwiftLogConsoleColors", package: "swift-log-console-colors") {
				.package(url: "https://github.com/nneuberger1/swift-log-console-colors", from: "1.0.3")
			},
			.product(name: "FileLogging", package: "swift-log-file") {
				.package(url: "https://github.com/crspybits/swift-log-file", from: "0.1.0")
			},
			.product(name: "Tagged", package: "swift-tagged") {
				.package(url: "https://github.com/pointfreeco/swift-tagged", exact: "0.10.0")
			},
			.product(name: "Validated", package: "swift-validated") {
				.package(url: "https://github.com/pointfreeco/swift-validated", exact: "0.2.1")
			},
			.product(name: "Overture", package: "swift-overture") {
				.package(url: "https://github.com/pointfreeco/swift-overture", exact: "0.5.0")
			},

		],
		tests: .yes(dependencies: [])
	),
])

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
			case feature(featureSuffixDroppedFromFolderName: Bool)
			case core
			case module(name: String)
			static let testing: Self = .module(name: "Testing")
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
		let disableConcurrencyChecks: Bool
		let isProduct: Bool

		static func feature(
			name: String,
			featureSuffixDroppedFromFolderName: Bool = false,
			remoteDependencies: [Package.Dependency]? = nil,
			dependencies: [Target.Dependency],
			exclude: [String] = [],
			resources: [Resource]? = nil,
			plugins: [Target.PluginUsage]? = nil,
			tests: Tests,
			disableConcurrencyChecks: Bool = false,
			isProduct: Bool = true
		) -> Self {
			.init(
				name: name,
				category: .feature(featureSuffixDroppedFromFolderName: featureSuffixDroppedFromFolderName),
				remoteDependencies: remoteDependencies,
				dependencies: dependencies + ["FeaturePrelude"],
				exclude: exclude,
				resources: resources,
				plugins: plugins,
				tests: tests,
				disableConcurrencyChecks: disableConcurrencyChecks,
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
			disableConcurrencyChecks: Bool = false,
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
				disableConcurrencyChecks: disableConcurrencyChecks,
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
			disableConcurrencyChecks: Bool = false,
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
				disableConcurrencyChecks: disableConcurrencyChecks,
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
			disableConcurrencyChecks: Bool = false,
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
				disableConcurrencyChecks: disableConcurrencyChecks,
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

		let nameOfTarget = module.name
		var nameOfTargetInPath = nameOfTarget
		switch module.category {
		case let .feature(featureSuffixDroppedFromFolderName):
			let needle = "Feature"
			if featureSuffixDroppedFromFolderName, nameOfTargetInPath.hasSuffix(needle) {
				nameOfTargetInPath.removeLast(needle.count)
			}
		default: break
		}
		let targetPath = {
			if let category = module.category {
				return "Sources/\(category.pathComponent)/\(nameOfTargetInPath)"
			} else {
				return "Sources/\(nameOfTargetInPath)"
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
				name: nameOfTarget,
				dependencies: dependencies,
				path: targetPath,
				exclude: module.exclude,
				resources: module.resources,
				swiftSettings: module.disableConcurrencyChecks ? [] : [
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
			let testTargetName = nameOfTarget + nameSuffix
			let testTargetPath = {
				if let category = module.category {
					return "Tests/\(category.pathComponent)/\(testTargetName)"
				} else {
					return "Tests/\(testTargetName)"
				}
			}()

			let testTargetDependencies = [.target(name: nameOfTarget)] + customAdditionalTestDependencies + {
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
				.library(name: nameOfTarget, targets: [nameOfTarget]),
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
