@testable import Radix_Wallet_Dev
import XCTest

// MARK: - AppFeatureTests
@MainActor
final class AppFeatureTests: TestCase {
	let networkID = NetworkID.nebunet

	func test_initialAppState_whenAppLaunches_thenInitialAppStateIsSplash() {
		let appState = App.State()
		XCTAssertEqual(appState.root, .splash(.init()))
	}

	func test_removedWallet_whenWalletRemovedFromMainScreen_thenNavigateToOnboarding() async {
		// given
		let store = TestStore(
			initialState: App.State(root: .main(.previewValue)),
			reducer: App.init
		) {
			$0.gatewaysClient.gatewaysValues = { AsyncLazySequence([.init(current: .default)]).eraseToAnyAsyncSequence() }
		}
		// when
		await store.send(.child(.main(.delegate(.removedWallet)))) {
			$0.root = .onboardingCoordinator(.init())
		}
	}

	func test_splash__GIVEN__an_existing_profile__WHEN__existing_profile_loaded__THEN__we_navigate_to_main() async throws {
		// GIVEN: an existing profile
		let accountRecoveryNeeded = true
		let clock = TestClock()
		let store = TestStore(
			initialState: App.State(root: .splash(.init())),
			reducer: App.init
		) {
			$0.errorQueue.errors = { AsyncLazySequence([]).eraseToAnyAsyncSequence() }
			$0.continuousClock = clock

			$0.deviceFactorSourceClient.isAccountRecoveryNeeded = {
				accountRecoveryNeeded
			}
		}

		// THEN: navigate to main
		await store.send(.child(.splash(.delegate(.completed(Profile.withOneAccount, accountRecoveryNeeded: accountRecoveryNeeded))))) {
			$0.root = .main(.init(home: .init(babylonAccountRecoveryIsNeeded: accountRecoveryNeeded)))
		}

		await clock.run() // fast-forward clock to the end of time
	}

	func test__GIVEN__splash__WHEN__loadProfile_results_in_noProfile__THEN__navigate_to_onboarding() async {
		// given
		let clock = TestClock()
		let store = TestStore(
			initialState: App.State(root: .splash(.init())),
			reducer: App.init
		) {
			$0.errorQueue = .liveValue
			$0.continuousClock = clock
		}

		// then
		await store.send(.child(.splash(.delegate(.completed(Profile.withNoAccounts, accountRecoveryNeeded: false))))) {
			$0.root = .onboardingCoordinator(.init())
		}

		await clock.run() // fast-forward clock to the end of time
	}
}

// extension PrivateHDFactorSource {
//	static let testValue: Self = {
//		let mnemonic = try! Mnemonic(
//			phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong",
//			language: .english
//		)
//
//		let passphrase = ""
//		let mnemonicWithPassphrase = MnemonicWithPassphrase(
//			mnemonic: mnemonic,
//			passphrase: passphrase
//		)
//		let factorSource = try! DeviceFactorSource.babylon(
//			mnemonicWithPassphrase: mnemonicWithPassphrase
//		)
//
//		return try! Self(
//			mnemonicWithPassphrase: mnemonicWithPassphrase,
//			factorSource: factorSource
//		)
//	}()
// }

extension Profile.Network.Account {
	static let testValue = Self.testValueIdx0

	static let testValueIdx0 = Self.testValue(
		name: "First",
		index: 0
	)

	static let testValueIdx1 = Self.testValue(
		name: "Second",
		index: 1
	)

	static func testValue(
		name nameOfFirstAccount: String,
		index: HD.Path.Component.Child.Value = 0,
		privateHDFactorSource maybePrivateHDFactorSource: PrivateHDFactorSource? = nil
	) -> Self {
		let privateHDFactorSource = maybePrivateHDFactorSource ?? PrivateHDFactorSource.testValue

		let networkID = NetworkID.mainnet
		let hdFactorInstance = try! privateHDFactorSource.hdRoot(index: index)

		return try! Profile.Network.Account(
			networkID: networkID,
			address: Profile.Network.Account.deriveVirtualAddress(
				networkID: networkID,
				factorInstance: hdFactorInstance
			),
			securityState: .unsecured(
				.init(
					entityIndex: index,
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

	static let testValueIdx0 = Self.testValue(
		name: "First",
		index: 0
	)

	static let testValueIdx1 = Self.testValue(
		name: "Second",
		index: 1
	)

	static func testValue(
		name nameOfPersona: String,
		index: HD.Path.Component.Child.Value = 0,
		privateHDFactorSource maybePrivateHDFactorSource: PrivateHDFactorSource? = nil
	) -> Self {
		let privateHDFactorSource = maybePrivateHDFactorSource ?? PrivateHDFactorSource.testValue

		let networkID = NetworkID.mainnet
		let hdFactorInstance = try! privateHDFactorSource.hdRoot(index: index)

		return try! Profile.Network.Persona(
			networkID: networkID,
			address: Profile.Network.Persona.deriveVirtualAddress(
				networkID: networkID,
				factorInstance: hdFactorInstance
			),
			securityState: .unsecured(
				.init(
					entityIndex: index,
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
			Profile.Network.Account.testValue(
				name: nameOfFirstAccount,
				privateHDFactorSource: privateHDFactorSource
			)
		)

		let network = Profile.Network(
			networkID: networkID,
			accounts: .init(rawValue: accounts)!,
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
	_ operation: @escaping @autoclosure () -> R
) -> R {
	withTestClients({ $0 }, operation: operation)
}

@discardableResult
public func withTestClients<R>(
	_ updateValuesForOperation: (inout DependencyValues) throws -> Void,
	operation: () throws -> R
) rethrows -> R {
	try withDependencies({
		configureTestClients(&$0)
		try updateValuesForOperation(&$0)
	}, operation: operation)
}

@_unsafeInheritExecutor
@discardableResult
public func withTestClients<R>(
	_ updateValuesForOperation: (inout DependencyValues) async throws -> Void,
	operation: () async throws -> R
) async rethrows -> R {
	try await withDependencies({
		configureTestClients(&$0)
		try await updateValuesForOperation(&$0)
	}, operation: operation)
}

private func configureTestClients(
	_ d: inout DependencyValues
) {
	d.uuid = .incrementing
	d.date = .constant(Date(timeIntervalSince1970: 0))
	d.mnemonicClient.generate = { _, _ in .testValue }
	d.secureStorageClient.saveDeviceInfo = { _ in }
	d.secureStorageClient.deprecatedLoadDeviceID = { nil }
	d.secureStorageClient.loadDeviceInfo = { .testValueABBA }
	d.secureStorageClient.loadProfileHeaderList = { nil }
	d.secureStorageClient.saveProfileHeaderList = { _ in }
	d.secureStorageClient.deleteDeprecatedDeviceID = {}
	d.secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs = { _, _ in }
	d.secureStorageClient.saveMnemonicForFactorSource = { _ in }
	d.secureStorageClient.saveProfileSnapshot = { _ in }
	d.secureStorageClient.loadProfileSnapshotData = { _ in nil }
	d.secureStorageClient.loadProfileSnapshot = { _ in nil }
	d.date = .constant(Date(timeIntervalSince1970: 0))
	d.userDefaultsClient.stringForKey = { _ in nil }
	d.userDefaultsClient.setString = { _, _ in }
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
