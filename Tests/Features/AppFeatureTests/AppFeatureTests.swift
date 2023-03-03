@testable import AppFeature
import FeatureTestingPrelude
import OnboardingClient
import OnboardingFeature
@testable import Profile
@testable import SplashFeature

private let ephemeralPrivateProfile: Profile.Ephemeral.Private = withDependencies { $0.uuid = .incrementing } operation: {
	Profile.Ephemeral.Private.testValue(hint: "AppFeatureTest")
}

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
		) {
			$0.onboardingClient.loadEphemeralPrivateProfile = {
				ephemeralPrivateProfile
			}
		}
		// when
		await store.send(.child(.main(.delegate(.removedWallet))))
		await store.receive(.internal(.loadEphemeralPrivateProfileResult(.success(ephemeralPrivateProfile)))) {
			// then
			$0.root = .onboardingCoordinator(.init(ephemeralPrivateProfile: ephemeralPrivateProfile))
		}
	}

	func test_splash__GIVEN__an_existing_profile__WHEN__existing_profile_loaded__THEN__we_navigate_to_main() async throws {
		// GIVEN: an existing profile (ephemeralPrivateProfile)
		let testScheduler = DispatchQueue.test
		let store = TestStore(
			initialState: App.State(root: .splash(.init())),
			reducer: App()
		) {
			$0.mainQueue = testScheduler.eraseToAnyScheduler()
			$0.onboardingClient.loadEphemeralPrivateProfile = {
				ephemeralPrivateProfile
			}
			$0.errorQueue.errors = { AsyncLazySequence([]).eraseToAnyAsyncSequence() }
		}

		// WHEN: existing profile is loaded
		await store.send(.child(.splash(.internal(.loadProfileOutcome(.existingProfileLoaded))))) {
			$0.root = .splash(.init(biometricsCheckFailedAlert: nil, loadProfileOutcome: .existingProfileLoaded))
		}

		await testScheduler.advance(by: .seconds(2))
		await store.receive(.child(.splash(.internal(.biometricsConfigResult(.success(.biometricsAndPasscodeSetUp))))))

		// then
		await store.receive(.child(.splash(.delegate(.loadProfileOutcome(.existingProfileLoaded)))))
			{
				$0.root = .main(.init())
			}

		await testScheduler.run() // fast-forward scheduler to the end of time
	}

	func test__GIVEN__splash__WHEN__loadProfile_results_in_noProfile__THEN__navigate_to_onboarding() async {
		// given
		let testScheduler = DispatchQueue.test
		let store = TestStore(
			initialState: App.State(root: .splash(.init())),
			reducer: App()
		) {
			$0.errorQueue = .liveValue
			$0.mainQueue = testScheduler.eraseToAnyScheduler()
			$0.onboardingClient.loadEphemeralPrivateProfile = {
				ephemeralPrivateProfile
			}
		}

		let viewTask = await store.send(.view(.task))

		// when
		await store.send(.child(.splash(.internal(.loadProfileOutcome(.newUser))))) {
			$0.root = .splash(.init(biometricsCheckFailedAlert: nil, loadProfileOutcome: .newUser))
		}

		await testScheduler.advance(by: .seconds(2))
		await store.receive(.child(.splash(.internal(.biometricsConfigResult(.success(.biometricsAndPasscodeSetUp))))))

		// then
		await store.receive(.child(.splash(.delegate(.loadProfileOutcome(.newUser)))))
		await store.receive(.internal(.loadEphemeralPrivateProfileResult(.success(ephemeralPrivateProfile)))) {
			$0.root = .onboardingCoordinator(.init(ephemeralPrivateProfile: ephemeralPrivateProfile))
		}

		await testScheduler.run() // fast-forward scheduler to the end of time
		await viewTask.cancel()
	}

	func test__GIVEN__splash__WHEN__loadProfile_results_in_decodingError__THEN__display_errorAlert_and_navigate_to_onboarding() async throws {
		// given
		let testScheduler = DispatchQueue.test
		let store = TestStore(
			initialState: App.State(root: .splash(.init())),
			reducer: App()
		) {
			$0.errorQueue = .liveValue
			$0.mainQueue = testScheduler.eraseToAnyScheduler()
			$0.onboardingClient.loadEphemeralPrivateProfile = {
				ephemeralPrivateProfile
			}
		}

		let viewTask = await store.send(.view(.task))

		// when
		let decodingError = DecodingError.valueNotFound(Profile.self, .init(codingPath: [], debugDescription: "Something went wrong"))
		let error = Profile.JSONDecodingError.KnownDecodingError.decodingError(.init(decodingError: decodingError))
		let foobar: Profile.JSONDecodingError = .known(error)
		let failure: Profile.LoadingFailure = .decodingFailure(json: Data(), foobar)

		let outcome = LoadProfileOutcome.usersExistingProfileCouldNotBeLoaded(failure: failure)
		await store.send(.child(.splash(.internal(.loadProfileOutcome(outcome))))) {
			$0.root = .splash(.init(biometricsCheckFailedAlert: nil, loadProfileOutcome: outcome))
		}

		await testScheduler.advance(by: .seconds(2))
		await store.receive(.child(.splash(.internal(.biometricsConfigResult(.success(.biometricsAndPasscodeSetUp))))))

		// then
		await store.receive(.child(.splash(.delegate(.loadProfileOutcome(outcome)))))

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

		await store.receive(.internal(.loadEphemeralPrivateProfileResult(.success(ephemeralPrivateProfile)))) {
			$0.root = .onboardingCoordinator(.init(ephemeralPrivateProfile: ephemeralPrivateProfile))
		}

		await store.send(.view(.alert(.dismiss))) {
			// then
			$0.alert = nil
		}

		await testScheduler.run() // fast-forward scheduler to the end of time
		await viewTask.cancel()
	}

	func test__GIVEN__splash__WHEN__loadProfile_results_in_failedToCreateProfileFromSnapshot__THEN__display_errorAlert_when_user_proceeds_incompatible_profile_is_deleted_from_keychain_and_navigate_to_onboarding() async throws {
		// given
		let expectationProfileGotDeleted = expectation(description: "Profile gets deleted")
		let testScheduler = DispatchQueue.test
		let store = TestStore(
			initialState: App.State(root: .splash(.init())),
			reducer: App()
		) {
			$0.errorQueue = .liveValue
			$0.mainQueue = testScheduler.eraseToAnyScheduler()

			$0.secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs = {
				expectationProfileGotDeleted.fulfill()
			}
			$0.onboardingClient.loadEphemeralPrivateProfile = {
				ephemeralPrivateProfile
			}
		}

		let viewTask = await store.send(.view(.task))

		// when
		struct SomeError: Swift.Error {}
		let badVersion: ProfileSnapshot.Version = 0
		let failedToCreateProfileFromSnapshot = Profile.FailedToCreateProfileFromSnapshot(version: badVersion, error: SomeError())

		let outcome = LoadProfileOutcome.usersExistingProfileCouldNotBeLoaded(failure: Profile.LoadingFailure.failedToCreateProfileFromSnapshot(failedToCreateProfileFromSnapshot))
		await store.send(.child(.splash(.internal(.loadProfileOutcome(outcome))))) {
			$0.root = .splash(.init(biometricsCheckFailedAlert: nil, loadProfileOutcome: outcome))
		}

		await testScheduler.advance(by: .seconds(2))
		await store.receive(.child(.splash(.internal(.biometricsConfigResult(.success(.biometricsAndPasscodeSetUp))))))

		await store.receive(.child(.splash(.delegate(.loadProfileOutcome(outcome))))) {
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
		await store.receive(.internal(.incompatibleProfileDeleted))
		await store.receive(.internal(.loadEphemeralPrivateProfileResult(.success(ephemeralPrivateProfile)))) {
			$0.root = .onboardingCoordinator(.init(ephemeralPrivateProfile: ephemeralPrivateProfile))
		}

		waitForExpectations(timeout: 1)
		await testScheduler.run() // fast-forward scheduler to the end of time
		await viewTask.cancel()
	}

	func test__GIVEN__splash__WHEN__loadProfile_results_in_profileVersionOutdated__THEN__display_errorAlert_when_user_proceeds_incompatible_profile_is_deleted_from_keychain_and_navigate_to_onboarding() async throws {
		// given
		let profileDeletedExpectation = expectation(description: "Profile got deleted")
		let testScheduler = DispatchQueue.test
		let store = TestStore(
			initialState: App.State(root: .splash(.init())),
			reducer: App()
		) {
			$0.errorQueue = .liveValue
			$0.mainQueue = testScheduler.eraseToAnyScheduler()
			$0.secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs = {
				profileDeletedExpectation.fulfill()
			}
			$0.onboardingClient.loadEphemeralPrivateProfile = {
				ephemeralPrivateProfile
			}
		}

		let viewTask = await store.send(.view(.task))

		// when
		struct SomeError: Swift.Error {}
		let badVersion: ProfileSnapshot.Version = 0

		let outcome = LoadProfileOutcome.usersExistingProfileCouldNotBeLoaded(failure: .profileVersionOutdated(json: Data([0xDE, 0xAD]), version: badVersion))

		await store.send(.child(.splash(.internal(.loadProfileOutcome(outcome))))) {
			$0.root = .splash(.init(biometricsCheckFailedAlert: nil, loadProfileOutcome: outcome))
		}

		await testScheduler.advance(by: .seconds(2))
		await store.receive(.child(.splash(.internal(.biometricsConfigResult(.success(.biometricsAndPasscodeSetUp))))))

		await store.receive(.child(.splash(.delegate(.loadProfileOutcome(outcome))))) {
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
		await store.receive(.internal(.incompatibleProfileDeleted))
		await store.receive(.internal(.loadEphemeralPrivateProfileResult(.success(ephemeralPrivateProfile)))) {
			$0.root = .onboardingCoordinator(.init(ephemeralPrivateProfile: ephemeralPrivateProfile))
		}

		waitForExpectations(timeout: 1)
		await testScheduler.run() // fast-forward scheduler to the end of time
		await viewTask.cancel()
	}
}
