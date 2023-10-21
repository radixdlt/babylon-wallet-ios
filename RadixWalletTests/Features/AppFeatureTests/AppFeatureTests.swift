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
		await store.send(.child(.splash(.delegate(.completed(Profile.testValue, accountRecoveryNeeded: accountRecoveryNeeded))))) {
			$0.root = .main(.init(home: .init(babylonAccountRecoveryIsNeeded: accountRecoveryNeeded)))
		}

		await clock.run() // fast-forward clock to the end of time
	}
	/*
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

	 	let viewTask = await store.send(.view(.task))

	 	// then
	 	await store.send(.child(.splash(.delegate(.completed(.newUser, accountRecoveryNeeded: false))))) {
	 		$0.root = .onboardingCoordinator(.init())
	 	}

	 	await clock.run() // fast-forward clock to the end of time
	 	await viewTask.cancel()
	 }

	 func test__GIVEN__splash__WHEN__loadProfile_results_in_decodingError__THEN__display_errorAlert_and_navigate_to_onboarding() async throws {
	 	// given
	 	let clock = TestClock()
	 	let store = TestStore(
	 		initialState: App.State(root: .splash(.init())),
	 		reducer: App.init
	 	) {
	 		$0.errorQueue = .liveValue
	 		$0.continuousClock = clock
	 	}

	 	let viewTask = await store.send(.view(.task))

	 	// when
	 	let decodingError = DecodingError.valueNotFound(Profile.self, .init(codingPath: [], debugDescription: "Something went wrong"))
	 	let error = Profile.JSONDecodingError.KnownDecodingError.decodingError(.init(decodingError: decodingError))
	 	let foobar: Profile.JSONDecodingError = .known(error)
	 	let failure: Profile.LoadingFailure = .decodingFailure(json: Data(), foobar)

	 	let outcome = LoadProfileOutcome.usersExistingProfileCouldNotBeLoaded(failure: failure)

	 	// then
	 	await store.send(.child(.splash(.delegate(.completed(outcome, accountRecoveryNeeded: false))))) {
	 		$0.root = .onboardingCoordinator(.init())
	 	}

	 	await clock.run() // fast-forward clock to the end of time
	 	await viewTask.cancel()
	 }

	 func test__GIVEN__splash__WHEN__invalid_profile__THEN__deleted_and_user_is_onboarded() async throws {
	 	let expectationProfileGotDeleted = expectation(description: "Profile gets deleted")
	 	let clock = TestClock()

	 	let store = TestStore(
	 		// 🫴 GIVEN splash
	 		initialState: App.State(root: .splash(.init())),
	 		reducer: App.init
	 	) {
	 		$0.errorQueue = .liveValue
	 		$0.continuousClock = clock
	 	}
	 	store.exhaustivity = .off
	 	let viewTask = await store.send(.view(.task))

	 	await store.send(.child(.splash(.delegate(
	 		.completed(
	 			.usersExistingProfileCouldNotBeLoaded(
	 				failure: .failedToCreateProfileFromSnapshot(
	 					// 🕑 WHEN invalid profile
	 					Profile.FailedToCreateProfileFromSnapshot(version: 0, error: NoopError())
	 				)
	 			),
	 			accountRecoveryNeeded: false
	 		)
	 	))))

	 	store.dependencies.appPreferencesClient.deleteProfileAndFactorSources = { _ in
	 		// ➡️ THEN delete user...
	 		expectationProfileGotDeleted.fulfill()
	 	}
	 	await store.send(.view(.alert(.presented(.incompatibleProfileErrorAlert(.deleteWalletDataButtonTapped)))))
	 	await store.receive(.internal(.incompatibleProfileDeleted)) {
	 		$0.root = .onboardingCoordinator(.init())
	 	}

	 	await viewTask.cancel()
	 	await clock.run() // fast-forward clock to the end of time
	 	await fulfillment(of: [expectationProfileGotDeleted])
	 }

	 func test__GIVEN__splash__WHEN__loadProfile_results_in_profileVersionOutdated__THEN__display_errorAlert_when_user_proceeds_incompatible_profile_is_deleted_from_keychain_and_navigate_to_onboarding() async throws {
	 	// given
	 	let profileDeletedExpectation = expectation(description: "Profile got deleted")
	 	let clock = TestClock()
	 	let store = TestStore(
	 		initialState: App.State(root: .splash(.init())),
	 		reducer: App.init
	 	) {
	 		$0.errorQueue = .liveValue
	 		$0.continuousClock = clock
	 		$0.appPreferencesClient.deleteProfileAndFactorSources = { _ in
	 			profileDeletedExpectation.fulfill()
	 		}
	 	}

	 	let viewTask = await store.send(.view(.task))

	 	// when
	 	struct SomeError: Swift.Error {}
	 	let badVersion: ProfileSnapshot.Header.Version = 0

	 	let outcome = LoadProfileOutcome.usersExistingProfileCouldNotBeLoaded(failure: .profileVersionOutdated(json: Data([0xDE, 0xAD]), version: badVersion))

	 	await store.send(.child(.splash(.delegate(.completed(outcome, accountRecoveryNeeded: false))))) {
	 		$0.alert = .incompatibleProfileErrorAlert(
	 			.init(
	 				title: { TextState("Wallet Data is Incompatible") },
	 				actions: {
	 					ButtonState(role: .destructive, action: .deleteWalletDataButtonTapped) {
	 						TextState("Delete Wallet Data")
	 					}
	 				},
	 				message: { TextState("For this Preview wallet version, you must delete your wallet data to continue.") }
	 			)
	 		)
	 	}

	 	await store.send(.view(.alert(.presented(.incompatibleProfileErrorAlert(.deleteWalletDataButtonTapped))))) {
	 		$0.alert = nil
	 	}
	 	await store.receive(.internal(.incompatibleProfileDeleted)) {
	 		$0.root = .onboardingCoordinator(.init())
	 	}

	 	await fulfillment(of: [profileDeletedExpectation], timeout: 1.0)
	 	await clock.run() // fast-forward clock to the end of time
	 	await viewTask.cancel()
	 }
	 */
}

extension Profile {
	static let testValue: Self = testValue()
	static func testValue(nameOfFirstAccount: String? = nil) -> Self {
		let mnemonic = try! Mnemonic(phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong", language: .english)
		let passphrase = ""
		let mnemonicWithPassphrase = MnemonicWithPassphrase(mnemonic: mnemonic, passphrase: passphrase)
		let factorSource = try! DeviceFactorSource.babylon(
			mnemonicWithPassphrase: mnemonicWithPassphrase
		)

		return .init(
			header: .testValue,
			factorSources: NonEmpty(rawValue: [
				factorSource.embed(),
			])!
		)
	}
}

extension ProfileSnapshot.Header {
	static let testValue: Self = testValue()
	static func testValue(profileID: UUID? = nil) -> Self {
		fatalError()
	}
}
