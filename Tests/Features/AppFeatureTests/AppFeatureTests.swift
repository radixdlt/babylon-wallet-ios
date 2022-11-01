@testable import AppFeature
import ComposableArchitecture
import OnboardingFeature
import Profile
import SplashFeature
import TestUtils

@MainActor
final class AppFeatureTests: TestCase {
	let networkID = NetworkID.primary

	func test_initialAppState_whenAppLaunches_thenInitialAppStateIsSplash() {
		let appState = App.State()
		let expectedInitialAppState: App.State = .splash(.init())
		XCTAssertEqual(appState, expectedInitialAppState)
	}

	func test_removedWallet_whenWalletRemovedFromMainScreen_thenNavigateToOnboarding() async throws {
		// given
		let initialState = App.State.main(.placeholder)
		let store = TestStore(
			initialState: initialState,
			reducer: App.reducer,
			environment: .unimplemented
		)

		// when
		_ = await store.send(.main(.coordinate(.removedWallet)))
		_ = await store.receive(.coordinate(.onboard)) {
			// then
			$0 = .onboarding(.init())
		}
	}

	func test_onboaring__GIVEN__no_profile__WHEN__new_profile_created__THEN__it_is_injected_into_profileClient_and_we_navigate_to_main() async throws {
		var environment: App.Environment = .unimplemented
		let newProfile = try await Profile.new(networkID: networkID, mnemonic: .generate())
		environment.profileClient.injectProfile = {
			XCTAssertEqual($0, newProfile) // assert correct profile is injected
		}

		let store = TestStore(
			// GIVEN: No profile (Onboarding)
			initialState: .onboarding(Onboarding.State(newProfile: .init())),
			reducer: App.reducer,
			environment: environment
		)

		// WHEN: a new profile is created
		_ = await store.send(.onboarding(.newProfile(.coordinate(.finishedCreatingNewProfile(newProfile)))))
		_ = await store.receive(.onboarding(.coordinate(.onboardedWithProfile(newProfile, isNew: true))))

		// THEN: it is injected into ProfileClient...
		_ = await store.receive(.internal(.injectProfileIntoProfileClient(newProfile)))

		// THEN: ... and we navigate to main
		await store.receive(.coordinate(.toMain)) {
			$0 = .main(.init())
		}
	}

	func test_splash__GIVEN__an_existing_profile__WHEN__existing_profile_loaded__THEN__it_is_injected_into_profileClient_and_we_navigate_to_main() async throws {
		// GIVEN: an existing profile
		let existingProfile = try await Profile.new(networkID: networkID, mnemonic: .generate())

		let testScheduler = DispatchQueue.test
		var environment: App.Environment = .unimplemented
		environment.mainQueue = testScheduler.eraseToAnyScheduler()
		environment.profileClient.injectProfile = {
			XCTAssertEqual($0, existingProfile) // assert correct profile is injected
		}
		let store = TestStore(
			initialState: .splash(.init()),
			reducer: App.reducer,
			environment: environment
		)

		// WHEN: existing profile is loaded
		_ = await store.send(.splash(.internal(.system(.loadProfileResult(.success(existingProfile))))))

		_ = await store.receive(.splash(.internal(.coordinate(.loadProfileResult(.profileLoaded(existingProfile))))))

		await testScheduler.advance(by: .milliseconds(110))
		_ = await store.receive(.splash(.coordinate(.loadProfileResult(.profileLoaded(existingProfile)))))

		// THEN: it is injected into ProfileClient...
		_ = await store.receive(.internal(.injectProfileIntoProfileClient(existingProfile)))
		// THEN: ... and we navigate to main
		await store.receive(.coordinate(.toMain)) {
			$0 = .main(.init())
		}
	}

	func test_loadWalletResult_whenWalletLoadingFailedBecauseDecodingError_thenDoNothingForNow() async throws {
		// given
		let initialState = App.State.splash(.init())
		let reason = "FAIL_FROM_TEST"
		let loadProfileResult = SplashLoadProfileResult.noProfile(reason: reason, failedToDecode: true)
		let store = TestStore(
			initialState: initialState,
			reducer: App.reducer,
			environment: .unimplemented
		)

		// when
		_ = await store.send(.splash(.coordinate(.loadProfileResult(loadProfileResult))))

		// then
		_ = await store.receive(.coordinate(.failedToCreateOrImportProfile(reason: "Failed to decode profile: FAIL_FROM_TEST")))
	}

	func test_loadWalletResult_whenWalletLoadingFailedBecauseNoWalletFound_thenNavigateToOnboarding() async {
		// given
		let initialState = App.State.splash(.init())
		let reason = "Failed to load profile"
		let loadProfileResult = SplashLoadProfileResult.noProfile(reason: reason, failedToDecode: false)
		let store = TestStore(
			initialState: initialState,
			reducer: App.reducer,
			environment: .unimplemented
		)

		// when
		_ = await store.send(.splash(.coordinate(.loadProfileResult(loadProfileResult))))

		// then
		await store.receive(.coordinate(.onboard)) {
			$0 = .onboarding(.init())
		}
	}
}
