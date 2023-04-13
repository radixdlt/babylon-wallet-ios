@testable import AppFeature
import FeatureTestingPrelude
import OnboardingClient
import OnboardingFeature
@testable import Profile
@testable import SplashFeature

// MARK: - AppFeatureTests
@MainActor
final class AppFeatureTests: TestCase {
	let networkID = NetworkID.nebunet

	func test_initialAppState_whenAppLaunches_thenInitialAppStateIsSplash() {
		let appState = App.State()
		XCTAssertEqual(appState.root, .splash(.init()))
		XCTAssertNil(appState.alert)
	}

	func test_removedWallet_whenWalletRemovedFromMainScreen_thenNavigateToOnboarding() async {
		// given
		let store = TestStore(
			initialState: App.State(root: .main(.previewValue)),
			reducer: App()
		)
		// when
		await store.send(.child(.main(.delegate(.removedWallet)))) {
			// then
			$0.root = .onboardingCoordinator(.init())
		}
	}

	func test_splash__GIVEN__an_existing_profile__WHEN__existing_profile_loaded__THEN__we_navigate_to_main() async throws {
		// GIVEN: an existing profile (ephemeralPrivateProfile)
		let clock = TestClock()
		let store = TestStore(
			initialState: App.State(root: .splash(.init())),
			reducer: App()
		) {
			$0.errorQueue.errors = { AsyncLazySequence([]).eraseToAnyAsyncSequence() }
			$0.continuousClock = clock
		}

		// then
		await store.send(.child(.splash(.delegate(.loadProfileOutcome(.existingProfileLoaded))))) {
			$0.root = .main(.init())
		}

		await clock.run() // fast-forward clock to the end of time
	}

	func test__GIVEN__splash__WHEN__loadProfile_results_in_noProfile__THEN__navigate_to_onboarding() async {
		// given
		let clock = TestClock()
		let store = TestStore(
			initialState: App.State(root: .splash(.init())),
			reducer: App()
		) {
			$0.errorQueue = .liveValue
			$0.continuousClock = clock
		}

		let viewTask = await store.send(.view(.task))

		// then
		await store.send(.child(.splash(.delegate(.loadProfileOutcome(.newUser))))) {
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
			reducer: App()
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
		await store.send(.child(.splash(.delegate(.loadProfileOutcome(outcome))))) {
			$0.root = .onboardingCoordinator(.init())
		}

		await store.receive(.internal(.displayErrorAlert(
			App.UserFacingError(foobar)
		))) {
			$0.alert = .userErrorAlert(
				.init(
					title: { TextState("An Error Occurred") },
					actions: {},
					message: { TextState("Failed to create Wallet from backup: valueNotFound(Profile.Profile, Swift.DecodingError.Context(codingPath: [], debugDescription: \"Something went wrong\", underlyingError: nil))") }
				)
			)
		}

		await store.send(.view(.alert(.dismiss))) {
			// then
			$0.alert = nil
		}

		await clock.run() // fast-forward clock to the end of time
		await viewTask.cancel()
	}

	func test__GIVEN__splash__WHEN__loadProfile_results_in_failedToCreateProfileFromSnapshot__THEN__display_errorAlert_when_user_proceeds_incompatible_profile_is_deleted_from_keychain_and_navigate_to_onboarding() async throws {
		// given
		let expectationProfileGotDeleted = expectation(description: "Profile gets deleted")
		let clock = TestClock()
		let store = TestStore(
			initialState: App.State(root: .splash(.init())),
			reducer: App()
		) {
			$0.errorQueue = .liveValue
			$0.continuousClock = clock

			$0.secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs = {
				expectationProfileGotDeleted.fulfill()
			}
		}

		let viewTask = await store.send(.view(.task))

		// when
		struct SomeError: Swift.Error {}
		let badVersion: ProfileSnapshot.Version = 0
		let failedToCreateProfileFromSnapshot = Profile.FailedToCreateProfileFromSnapshot(version: badVersion, error: SomeError())

		let outcome = LoadProfileOutcome.usersExistingProfileCouldNotBeLoaded(failure: Profile.LoadingFailure.failedToCreateProfileFromSnapshot(failedToCreateProfileFromSnapshot))

		await store.send(.child(.splash(.delegate(.loadProfileOutcome(outcome))))) {
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

		waitForExpectations(timeout: 1)
		await clock.run() // fast-forward clock to the end of time
		await viewTask.cancel()
	}

	func test__GIVEN__splash__WHEN__loadProfile_results_in_profileVersionOutdated__THEN__display_errorAlert_when_user_proceeds_incompatible_profile_is_deleted_from_keychain_and_navigate_to_onboarding() async throws {
		// given
		let profileDeletedExpectation = expectation(description: "Profile got deleted")
		let clock = TestClock()
		let store = TestStore(
			initialState: App.State(root: .splash(.init())),
			reducer: App()
		) {
			$0.errorQueue = .liveValue
			$0.continuousClock = clock
			$0.secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs = {
				profileDeletedExpectation.fulfill()
			}
		}

		let viewTask = await store.send(.view(.task))

		// when
		struct SomeError: Swift.Error {}
		let badVersion: ProfileSnapshot.Version = 0

		let outcome = LoadProfileOutcome.usersExistingProfileCouldNotBeLoaded(failure: .profileVersionOutdated(json: Data([0xDE, 0xAD]), version: badVersion))

		await store.send(.child(.splash(.delegate(.loadProfileOutcome(outcome))))) {
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

		waitForExpectations(timeout: 1)
		await clock.run() // fast-forward clock to the end of time
		await viewTask.cancel()
	}
}
