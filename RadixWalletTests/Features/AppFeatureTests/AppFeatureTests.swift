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

extension Profile {
	static let withOneAccount = withTestClients(Self.testValue())
	static let withNoAccounts = withTestClients(Self.testValue(nameOfFirstAccount: nil))

	static func testValue(
		nameOfFirstAccount: String? = "Main"
	) -> Self {
		let mnemonic = try! Mnemonic(
			phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong",
			language: .english
		)

		let passphrase = ""
		let mnemonicWithPassphrase = MnemonicWithPassphrase(
			mnemonic: mnemonic,
			passphrase: passphrase
		)
		let factorSource = try! DeviceFactorSource.babylon(
			mnemonicWithPassphrase: mnemonicWithPassphrase
		)
		let networkID = NetworkID.mainnet
		var accounts: IdentifiedArrayOf<Profile.Network.Account> = []
		if let nameOfFirstAccount {
			let hdRoot = try! mnemonicWithPassphrase.hdRoot()
			let derivationPath = DerivationPath(
				scheme: .cap26,
				path: "m/44H/1022H/10H/525H/1460H/0H"
			)
			let publicKey = try! hdRoot.derivePublicKey(
				path: derivationPath,
				curve: .curve25519
			)
			let hdFactorInstance = HierarchicalDeterministicFactorInstance(
				id: factorSource.id,
				publicKey: publicKey,
				derivationPath: derivationPath
			)

			try! accounts.append(
				Profile.Network.Account(
					networkID: networkID,
					address: Profile.Network.Account.deriveVirtualAddress(
						networkID: networkID,
						factorInstance: hdFactorInstance
					),
					securityState: .unsecured(
						.init(
							entityIndex: 0,
							transactionSigning: hdFactorInstance
						)
					),
					displayName: .init(
						rawValue: nameOfFirstAccount
					)!,
					extraProperties: .init(
						appearanceID: ._0
					)
				)
			)
		}

		let network = Profile.Network(
			networkID: networkID,
			accounts: accounts,
			personas: [],
			authorizedDapps: []
		)

		return Profile(
			header: .testValue,
			factorSources: NonEmpty(rawValue: [
				factorSource.embed(),
			])!,
			networks: [networkID: network]
		)
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
	d.secureStorageClient.loadDeviceInfo = { .testValue }
	d.secureStorageClient.loadProfileHeaderList = { nil }
	d.secureStorageClient.saveProfileHeaderList = { _ in }
	d.secureStorageClient.deleteDeprecatedDeviceID = {}
	d.secureStorageClient.saveMnemonicForFactorSource = { _ in }
	d.secureStorageClient.saveProfileSnapshot = { _ in }
	d.secureStorageClient.loadProfileSnapshotData = { _ in nil }
	d.date = .constant(Date(timeIntervalSince1970: 0))
	d.userDefaultsClient.stringForKey = { _ in nil }
	d.userDefaultsClient.setString = { _, _ in }
}

extension ProfileSnapshot.Header {
	static let testValue: Self = testValue()
	static func testValue(
		profileID: UUID? = nil,
		deviceID: UUID? = nil,
		date: Date? = nil
	) -> Self {
		let device: DeviceInfo = .testValue(deviceID: deviceID, date: date)
		return Self(
			creatingDevice: device,
			lastUsedOnDevice: device,
			id: profileID ?? 0xDEAD,
			lastModified: device.date,
			contentHint: .init(),
			snapshotVersion: .minimum
		)
	}
}

extension DeviceInfo {
	static let testValue: Self = testValue()
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
