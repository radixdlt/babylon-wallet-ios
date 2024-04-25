import Foundation
@testable import Radix_Wallet_Dev
import Sargon

extension Account {
	static let testValue = Self.testValueIdx0
	static let testValueIdx0 = Self.sample
	static let testValueIdx1 = Self.sampleOther
}

extension Persona {
	static let testValue = Self.testValueIdx0
	static let testValueIdx0 = Self.sample
	static let testValueIdx1 = Self.sampleOther
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
		privateHDFactorSource: PrivateHierarchicalDeterministicFactorSource = .testValue
	) {
		var account = Account.sampleMainnet
		account.displayName = try! .init(
			validating: nameOfFirstAccount
		)
		account.securityState = .unsecured(
			value: UnsecuredEntityControl(
				transactionSigning: HierarchicalDeterministicFactorInstance(
					factorSourceId: privateHDFactorSource.factorSource.id,
					publicKey: .sample
				),
				authenticationSigning: nil
			)
		)
		var accounts = Accounts(
			element: account
		)

		let network = ProfileNetwork(id: networkID, accounts: accounts, personas: [], authorizedDapps: [])

		self.networks = .init(element: network)
	}

	static func testValue(
		nameOfFirstAccount: String? = "Main",
		header: Header,
		privateHDFactorSource: PrivateHierarchicalDeterministicFactorSource = .testValueZooVote
	) -> Self {
		var profile = Profile(header: header, deviceFactorSource: privateHDFactorSource.factorSource)
		if let nameOfFirstAccount {
			profile.createMainnetWithOneAccount(name: nameOfFirstAccount, privateHDFactorSource: privateHDFactorSource)
			profile.header.contentHint.numberOfNetworks = 1
			profile.header.contentHint.numberOfPersonasOnAllNetworksInTotal = 0
			profile.header.contentHint.numberOfAccountsOnAllNetworksInTotal = 1
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
	d.mnemonicClient.generate = { _, _ in Mnemonic.sample }
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

extension Header {
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
			snapshotVersion: .v100,
			id: profileID ?? 0xDEAD,
			creatingDevice: deviceInfo,
			lastUsedOnDevice: deviceInfo,
			lastModified: deviceInfo.date,
			contentHint: .init(
				numberOfAccountsOnAllNetworksInTotal: 0,
				numberOfPersonasOnAllNetworksInTotal: 0,
				numberOfNetworks: 0
			)
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
		Self(id: deviceID ?? 0xABBA, date: date ?? Date(timeIntervalSince1970: 0), description: "testValue")
	}
}

extension MnemonicWithPassphrase {
	public static let testValueZooVote: Self = .init(mnemonic: .sample, passphrase: "")
	public static let testValueAbandonArt: Self = .init(mnemonic: .sampleOther, passphrase: "")
}

extension PrivateHierarchicalDeterministicFactorSource {
	static let testValue = Self.testValueZooVote

	static let testValueZooVote: Self = testValue(mnemonicWithPassphrase: .testValueZooVote)
	static let testValueAbandonArt: Self = testValue(mnemonicWithPassphrase: .testValueAbandonArt)

	public static func testValue(
		name: String,
		model: String,
		mnemonicWithPassphrase: MnemonicWithPassphrase = .testValueZooVote
	) -> Self {
		var bdfs = DeviceFactorSource.babylon(mnemonicWithPassphrase: mnemonicWithPassphrase, isMain: true)
		bdfs.hint.model = model
		bdfs.hint.name = name
		bdfs.common.addedOn = .init(timeIntervalSince1970: 0)
		bdfs.common.lastUsedOn = .init(timeIntervalSince1970: 0)
		return Self(mnemonicWithPassphrase: mnemonicWithPassphrase, factorSource: bdfs)
	}

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
//
//	func hdRoot(derivationPath: DerivationPath) throws -> HierarchicalDeterministicFactorInstance {
//		let hdRoot = try mnemonicWithPassphrase.hdRoot()
//
//		let publicKey = try! hdRoot.derivePublicKey(
//			path: derivationPath,
//			curve: .curve25519
//		)
//
//		return HierarchicalDeterministicFactorInstance(
//			id: factorSource.id,
//			publicKey: publicKey,
//			derivationPath: derivationPath
//		)
//	}
}

private let deviceName: String = "iPhone"
private let deviceModel: String = "iPhone"
// private let expectedDeviceDescription = DeviceInfo(
//	name: deviceName,
//	model: deviceModel.rawValue
// )
private let expectedDeviceDescription = DeviceInfo.sample
