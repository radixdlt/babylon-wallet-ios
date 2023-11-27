import Foundation
@testable import Radix_Wallet_Dev

extension Profile.Network.Account {
	static let testValue = Self.testValueIdx0

	static let testValueIdx0 = Self.makeTestValue(
		name: "First",
		index: 0
	)

	static let testValueIdx1 = Self.makeTestValue(
		name: "Second",
		index: 1
	)

	static func makeTestValue(
		name nameOfFirstAccount: String,
		networkID: NetworkID = .mainnet,
		index: HD.Path.Component.Child.Value = 0,
		privateHDFactorSource maybePrivateHDFactorSource: PrivateHDFactorSource? = nil
	) -> Self {
		let privateHDFactorSource = maybePrivateHDFactorSource ?? PrivateHDFactorSource.testValue
		let path = try! AccountBabylonDerivationPath(networkID: networkID, index: index, keyKind: .transactionSigning)

		let hdFactorInstance = try! privateHDFactorSource.hdRoot(derivationPath: path.wrapAsDerivationPath())

		return try! Profile.Network.Account(
			networkID: networkID,
			address: Profile.Network.Account.deriveVirtualAddress(
				networkID: networkID,
				factorInstance: hdFactorInstance
			),
			securityState: .unsecured(
				.init(
					transactionSigning: hdFactorInstance
				)
			),
			displayName: .init(
				rawValue: nameOfFirstAccount
			)!,
			extraProperties: .init(
				appearanceID: try! .init(id: .init(index))
			)
		)
	}
}

extension Profile.Network.Persona {
	static let testValue = Self.testValueIdx0

	static let testValueIdx0 = Self.makeTestValue(
		name: "First",
		index: 0
	)

	static let testValueIdx1 = Self.makeTestValue(
		name: "Second",
		index: 1
	)

	static func makeTestValue(
		name nameOfPersona: String,
		index: HD.Path.Component.Child.Value = 0,
		privateHDFactorSource maybePrivateHDFactorSource: PrivateHDFactorSource? = nil
	) -> Self {
		let privateHDFactorSource = maybePrivateHDFactorSource ?? PrivateHDFactorSource.testValue

		let derivationPath = DerivationPath(
			scheme: .cap26,
			path: "m/44H/1022H/10H/618H/1460H/\(index)H"
		)

		let networkID = NetworkID.mainnet
		let hdFactorInstance = try! privateHDFactorSource.hdRoot(derivationPath: derivationPath)

		return try! Profile.Network.Persona(
			networkID: networkID,
			address: Profile.Network.Persona.deriveVirtualAddress(
				networkID: networkID,
				factorInstance: hdFactorInstance
			),
			securityState: .unsecured(
				.init(
					transactionSigning: hdFactorInstance
				)
			),
			displayName: .init(
				rawValue: nameOfPersona
			)!
		)
	}
}

extension Profile {
	static let withOneAccount = Self.withOneAccountsDeviceInfo_ABBA_mnemonic_ZOO_VOTE
	static let withNoAccounts = Self.withNoAccountsDeviceInfo_ABBA_mnemonic_ZOO_VOTE

	static let withOneAccountsDeviceInfo_ABBA_mnemonic_ZOO_VOTE = withTestClients(
		Self.testValue(
			nameOfFirstAccount: "zoo...vote",
			header: .testValueProfileID_DEAD_deviceID_ABBA,
			privateHDFactorSource: .testValueZooVote
		)
	)
	static let withNoAccountsDeviceInfo_ABBA_mnemonic_ZOO_VOTE = withTestClients(
		Self.testValue(
			nameOfFirstAccount: nil,
			header: .testValueProfileID_DEAD_deviceID_ABBA,
			privateHDFactorSource: .testValueZooVote
		)
	)

	static let withOneAccountsDeviceInfo_ABBA_mnemonic_ABANDON_ART = withTestClients(
		Self.testValue(
			nameOfFirstAccount: "abandon...art",
			header: .testValueProfileID_FADE_deviceID_ABBA,
			privateHDFactorSource: .testValueAbandonArt
		)
	)
	static let withNoAccountsDeviceInfo_ABBA_mnemonic_ABANDON_ART = withTestClients(
		Self.testValue(
			nameOfFirstAccount: nil,
			header: .testValueProfileID_FADE_deviceID_ABBA,
			privateHDFactorSource: .testValueAbandonArt
		)
	)

	static let withOneAccountsDeviceInfo_BEEF_mnemonic_ABANDON_ART = withTestClients(
		Self.testValue(
			nameOfFirstAccount: "abandon...art",
			header: .testValueProfileID_FADE_deviceID_BEEF,
			privateHDFactorSource: .testValueAbandonArt
		)
	)
	static let withNoAccountsDeviceInfo_BEEF_mnemonic_ABANDON_ART = withTestClients(
		Self.testValue(
			nameOfFirstAccount: nil,
			header: .testValueProfileID_FADE_deviceID_BEEF,
			privateHDFactorSource: .testValueAbandonArt
		)
	)

	mutating func createMainnetWithOneAccount(
		name nameOfFirstAccount: String,
		privateHDFactorSource: PrivateHDFactorSource = .testValue
	) {
		var accounts = IdentifiedArrayOf<Profile.Network.Account>()
		accounts.append(
			Profile.Network.Account.makeTestValue(
				name: nameOfFirstAccount,
				privateHDFactorSource: privateHDFactorSource
			)
		)

		let network = Profile.Network(
			networkID: networkID,
			accounts: accounts,
			personas: [],
			authorizedDapps: []
		)

		self.networks = [networkID: network]
	}

	static func testValue(
		nameOfFirstAccount: String? = "Main",
		header: ProfileSnapshot.Header,
		privateHDFactorSource: PrivateHDFactorSource = .testValueZooVote
	) -> Self {
		var profile = Profile(
			header: header,
			factorSources: NonEmpty(rawValue: [
				privateHDFactorSource.factorSource.embed(),
			])!
		)

		if let nameOfFirstAccount {
			var header = header
			profile.createMainnetWithOneAccount(
				name: nameOfFirstAccount,
				privateHDFactorSource: privateHDFactorSource
			)
			header.contentHint = ProfileSnapshot.Header.ContentHint(
				numberOfAccountsOnAllNetworksInTotal: 1,
				numberOfPersonasOnAllNetworksInTotal: 0,
				numberOfNetworks: 1
			)
			profile.header = header
		}
		return profile
	}
}

@discardableResult
public func withTestClients<R>(
	userDefaults: UserDefaults.Dependency = .ephemeral(),
	_ operation: @escaping @autoclosure () -> R
) -> R {
	withTestClients(userDefaults: userDefaults, { $0 }, operation: operation)
}

@discardableResult
public func withTestClients<R>(
	userDefaults: UserDefaults.Dependency = .ephemeral(),
	_ updateValuesForOperation: (inout DependencyValues) throws -> Void,
	operation: () throws -> R
) rethrows -> R {
	try withDependencies({
		$0.userDefaults = userDefaults
		configureTestClients(&$0)
		return try updateValuesForOperation(&$0)
	}, operation: operation)
}

@_unsafeInheritExecutor
@discardableResult
public func withTestClients<R>(
	userDefaults: UserDefaults.Dependency = .ephemeral(),
	_ updateValuesForOperation: (inout DependencyValues) async throws -> Void,
	operation: () async throws -> R
) async rethrows -> R {
	try await withDependencies({
		$0.userDefaults = userDefaults
		configureTestClients(&$0)
		try await updateValuesForOperation(&$0)
	}, operation: operation)
}

private func configureTestClients(
	_ d: inout DependencyValues
) {
	d.device.$name = "Test"
	d.device.$model = "Test"
	d.entitiesVisibilityClient.hideAccounts = { _ in }
	d.entitiesVisibilityClient.hidePersonas = { _ in }
	d.uuid = .incrementing
	d.date = .constant(Date(timeIntervalSince1970: 0))
	d.mnemonicClient.generate = { _, _ in .testValue }
	d.secureStorageClient.saveDeviceInfo = { _ in }
	d.secureStorageClient.deprecatedLoadDeviceID = { nil }
	d.secureStorageClient.loadDeviceInfo = { .testValueABBA }
	d.secureStorageClient.loadProfileHeaderList = { nil }
	d.secureStorageClient.saveProfileHeaderList = { _ in }
	d.secureStorageClient.deleteDeprecatedDeviceID = {}
	d.secureStorageClient.containsMnemonicIdentifiedByFactorSourceID = { _ in true }
	d.secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs = { _, _ in }
	d.secureStorageClient.deleteMnemonicByFactorSourceID = { _ in }
	d.secureStorageClient.saveMnemonicForFactorSource = { _ in }
	d.secureStorageClient.saveProfileSnapshot = { _ in }
	d.secureStorageClient.loadProfileSnapshotData = { _ in nil }
	d.secureStorageClient.loadProfileSnapshot = { _ in nil }
	d.secureStorageClient.loadProfile = { _ in nil }
	d.date = .constant(Date(timeIntervalSince1970: 0))
}

extension ProfileSnapshot.Header {
	static let testValueProfileID_DEAD_deviceID_BEEF = Self.testValue(profileID: 0xDEAD, deviceID: 0xBEEF)
	static let testValueProfileID_DEAD_deviceID_ABBA = Self.testValue(profileID: 0xDEAD, deviceID: 0xABBA)
	static let testValueProfileID_FADE_deviceID_BEEF = Self.testValue(profileID: 0xFADE, deviceID: 0xBEEF)
	static let testValueProfileID_FADE_deviceID_ABBA = Self.testValue(profileID: 0xFADE, deviceID: 0xABBA)
	static func testValue(
		profileID: UUID? = nil,
		deviceID: UUID? = nil,
		date: Date? = nil
	) -> Self {
		.testValue(
			profileID: profileID,
			deviceInfo: .testValue(
				deviceID: deviceID,
				date: date
			)
		)
	}

	static func testValue(
		profileID: UUID? = nil,
		deviceInfo: DeviceInfo
	) -> Self {
		Self(
			creatingDevice: deviceInfo,
			lastUsedOnDevice: deviceInfo,
			id: profileID ?? 0xDEAD,
			lastModified: deviceInfo.date,
			contentHint: .init(),
			snapshotVersion: .minimum
		)
	}
}

extension DeviceInfo {
	static let testValue: Self = testValueABBA
	static let testValueABBA: Self = testValue(deviceID: 0xABBA)
	static let testValueBEEF: Self = testValue(deviceID: 0xBEEF)

	static func testValue(
		deviceID: UUID? = nil,
		date: Date? = nil
	) -> Self {
		Self(
			description: "testValue",
			id: deviceID ?? 0xABBA,
			date: date ?? Date(timeIntervalSince1970: 0)
		)
	}
}

extension PrivateHDFactorSource {
	static let testValue = Self.testValueZooVote

	static let testValueZooVote: Self = testValue(mnemonicWithPassphrase: .testValueZooVote)
	static let testValueAbandonArt: Self = testValue(mnemonicWithPassphrase: .testValueAbandonArt)

	static func testValue(
		mnemonicWithPassphrase: MnemonicWithPassphrase
	) -> Self {
		withDependencies {
			$0.date = .constant(Date(timeIntervalSince1970: 0))
		} operation: {
			Self.testValue(
				name: deviceName,
				model: deviceModel,
				mnemonicWithPassphrase: mnemonicWithPassphrase
			)
		}
	}

	func hdRoot(derivationPath: DerivationPath) throws -> HierarchicalDeterministicFactorInstance {
		let hdRoot = try mnemonicWithPassphrase.hdRoot()

		let publicKey = try! hdRoot.derivePublicKey(
			path: derivationPath,
			curve: .curve25519
		)

		return HierarchicalDeterministicFactorInstance(
			id: factorSource.id,
			publicKey: publicKey,
			derivationPath: derivationPath
		)
	}
}

private let deviceName: String = "iPhone"
private let deviceModel: DeviceFactorSource.Hint.Model = "iPhone"
private let expectedDeviceDescription = DeviceInfo.deviceDescription(
	name: deviceName,
	model: deviceModel.rawValue
)

extension Mnemonic {
	static let testValue: Self = "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong"
}
