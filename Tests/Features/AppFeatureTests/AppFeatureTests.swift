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
			reducer: App()
		)

		// when
		_ = await store.send(.child(.main(.delegate(.removedWallet)))) {
			// then
			$0 = .onboarding(.init())
		}
	}

	func test_onboaring__GIVEN__no_profile__WHEN__new_profile_created__THEN__it_is_injected_into_profileClient_and_we_navigate_to_main() async throws {
		let store = TestStore(
			initialState: .onboarding(Onboarding.State(newProfile: .init())),
			reducer: App()
		)
		let newProfile = try await Profile.new(networkID: networkID, mnemonic: .generate())
		let expectation = expectation(description: "Profile injected")
		store.dependencies.profileClient.injectProfile = { injected, mode in
			XCTAssertEqual(injected, newProfile)
			XCTAssert(mode == .injectAndPersistInKeychain)
			expectation.fulfill()
		}

		// when
		_ = await store.send(.child(.onboarding(.child(.newProfile(.delegate(.finishedCreatingNewProfile(newProfile)))))))

		// then
		_ = await store.receive(.child(.onboarding(.delegate(.onboardedWithProfile(newProfile, isNew: true)))))
		_ = await store.receive(.internal(.system(.injectProfileIntoProfileClientResult(.success(newProfile))))) {
			$0 = .main(.init())
		}

		wait(for: [expectation], timeout: 0)
	}

	func test_splash__GIVEN__an_existing_profile__WHEN__existing_profile_loaded__THEN__it_is_injected_into_profileClient_and_we_navigate_to_main() async throws {
		// GIVEN: an existing profile
		let existingProfile = try await Profile.new(networkID: networkID, mnemonic: .generate())

		let testScheduler = DispatchQueue.test
		let store = TestStore(
			initialState: .splash(.init()),
			reducer: App()
		)
		store.dependencies.mainQueue = testScheduler.eraseToAnyScheduler()
		let expectation = expectation(description: "Profile injected")
		store.dependencies.profileClient.injectProfile = { injected, mode in
			XCTAssertEqual(injected, existingProfile)
			XCTAssert(mode == .onlyInject)
			expectation.fulfill()
		}

		// WHEN: existing profile is loaded
		_ = await store.send(.child(.splash(.internal(.system(.loadProfileResult(.success(existingProfile)))))))

		// then
		_ = await store.receive(.child(.splash(.internal(.coordinate(.loadProfileResult(.profileLoaded(existingProfile)))))))

		await testScheduler.advance(by: .milliseconds(100))
		_ = await store.receive(.child(.splash(.delegate(.loadProfileResult(.profileLoaded(existingProfile))))))

		_ = await store.receive(.internal(.system(.injectProfileIntoProfileClientResult(.success(existingProfile))))) {
			$0 = .main(.init())
		}

		wait(for: [expectation], timeout: 0)
	}

	func test_loadWalletResult_whenWalletLoadingFailedBecauseDecodingError_thenDoNothingForNow() async throws {
		// given
		let initialState = App.State.splash(.init())
		let reason = "FAIL_FROM_TEST"
		let loadProfileResult = SplashLoadProfileResult.noProfile(reason: reason, failedToDecode: true)
		let store = TestStore(
			initialState: initialState,
			reducer: App()
		)

		// when
		_ = await store.send(.child(.splash(.delegate(.loadProfileResult(loadProfileResult)))))

		// then
		// TODO: does nothing for now (prints error)
	}

	func test_loadWalletResult_whenWalletLoadingFailedBecauseNoWalletFound_thenNavigateToOnboarding() async {
		// given
		let initialState = App.State.splash(.init())
		let reason = "Failed to load profile"
		let loadProfileResult = SplashLoadProfileResult.noProfile(reason: reason, failedToDecode: false)
		let store = TestStore(
			initialState: initialState,
			reducer: App()
		)

		// when
		_ = await store.send(.child(.splash(.delegate(.loadProfileResult(loadProfileResult))))) {
			// then
			$0 = .onboarding(.init())
		}
	}
}
