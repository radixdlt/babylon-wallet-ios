@testable import AppFeature
import ComposableArchitecture
import OnboardingFeature
import Profile
@testable import SplashFeature
import TestUtils

@MainActor
final class AppFeatureTests: TestCase {
	let networkID = NetworkID.primary

	func test_initialAppState_whenAppLaunches_thenInitialAppStateIsSplash() {
		let appState = App.State()
		XCTAssertEqual(appState.root, .splash(.init()))
		XCTAssertNil(appState.errorAlert)
	}

	func test_removedWallet_whenWalletRemovedFromMainScreen_thenNavigateToOnboarding() async {
		// given
		let store = TestStore(
			initialState: App.State(root: .main(.placeholder)),
			reducer: App()
		)

		// when
		_ = await store.send(.child(.main(.delegate(.removedWallet)))) {
			// then
			$0.root = .onboarding(.init())
		}
	}

	func test_onboaring__GIVEN__no_profile__WHEN__new_profile_created__THEN__it_is_injected_into_profileClient_and_we_navigate_to_main() async throws {
		let store = TestStore(
			initialState: App.State(root: .onboarding(.init(newProfile: .init()))),
			reducer: App()
		)
		let newProfile = try await Profile.new(networkAndGateway: .primary, mnemonic: .generate())
		let expectation = expectation(description: "Profile injected")
		store.dependencies.profileClient.injectProfile = { injected in
			XCTAssertEqual(injected, newProfile)
			expectation.fulfill()
		}

		// when
		_ = await store.send(.child(.onboarding(.child(.newProfile(.delegate(.finishedCreatingNewProfile(newProfile)))))))

		// then
		_ = await store.receive(.internal(.system(.injectProfileIntoProfileClientResult(.success(newProfile))))) {
			$0.root = .main(.init())
		}

		wait(for: [expectation], timeout: 0)
	}

	func test_splash__GIVEN__an_existing_profile__WHEN__existing_profile_loaded__THEN__it_is_injected_into_profileClient_and_we_navigate_to_main() async throws {
		// GIVEN: an existing profile
		let existingProfile = try await Profile.new(networkAndGateway: .primary, mnemonic: .generate())

		let testScheduler = DispatchQueue.test
		let store = TestStore(
			initialState: App.State(root: .splash(.init())),
			reducer: App()
		)
		store.dependencies.mainQueue = testScheduler.eraseToAnyScheduler()
		let expectation = expectation(description: "Profile injected")
		store.dependencies.profileClient.injectProfile = { injected in
			XCTAssertEqual(injected, existingProfile)
			expectation.fulfill()
		}

		// WHEN: existing profile is loaded
		_ = await store.send(.child(.splash(.internal(.system(.loadProfileResult(.success(existingProfile)))))))

		await testScheduler.advance(by: .milliseconds(100))

		// then
		_ = await store.receive(.child(.splash(.delegate(.profileLoaded(existingProfile)))))

		_ = await store.receive(.internal(.system(.injectProfileIntoProfileClientResult(.success(existingProfile))))) {
			$0.root = .main(.init())
		}

		await testScheduler.run() // fast-forward scheduler to the end of time

		wait(for: [expectation], timeout: 0)
	}

	func test_loadWalletResult_whenWalletLoadingFailedBecauseNoWalletFound_thenShowErrorAndNavigateToOnboarding() async {
		// given
		let store = TestStore(
			initialState: App.State(root: .splash(.init())),
			reducer: App()
		)

		let testScheduler = DispatchQueue.test

		store.dependencies.errorQueue = .liveValue
		store.dependencies.mainQueue = testScheduler.eraseToAnyScheduler()

		let viewTask = await store.send(.view(.task))

		// when
		_ = await store.send(.child(.splash(.internal(.system(.loadProfileResult(.success(nil)))))))

		await testScheduler.advance(by: .milliseconds(100))

		// then
		_ = await store.receive(.child(.splash(.delegate(.profileLoaded(nil))))) {
			$0.root = .onboarding(.init())
		}
		_ = await store.receive(.internal(.system(.displayErrorAlert(App.UserFacingError(Splash.NoProfileError()))))) {
			$0.errorAlert = .init(title: .init("An error ocurred"), message: .init("No profile saved yet"))
		}

		// when
		_ = await store.send(.view(.errorAlertDismissButtonTapped)) {
			// then
			$0.errorAlert = nil
		}

		await testScheduler.run() // fast-forward scheduler to the end of time
		await viewTask.cancel()
	}

	func test_loadWalletResult_whenWalletLoadingFailed_thenShowError() async throws {
		// given
		let store = TestStore(
			initialState: App.State(root: .splash(.init())),
			reducer: App()
		)

		let testScheduler = DispatchQueue.test

		store.dependencies.errorQueue = .liveValue
		store.dependencies.mainQueue = testScheduler.eraseToAnyScheduler()

		let viewTask = await store.send(.view(.task))

		// when
		let decodingError = DecodingError.valueNotFound(Profile.self, .init(codingPath: [], debugDescription: "Something went wrong"))
		_ = await store.send(.child(.splash(.internal(.system(.loadProfileResult(.failure(decodingError)))))))

		await testScheduler.advance(by: .milliseconds(100))

		// then
		_ = await store.receive(.internal(.system(.displayErrorAlert(App.UserFacingError(Splash.FailedToDecodeProfileError(error: decodingError)))))) {
			$0.errorAlert = .init(title: .init("An error ocurred"), message: .init("Failed to decode profile: valueNotFound(Profile.Profile, Swift.DecodingError.Context(codingPath: [], debugDescription: \"Something went wrong\", underlyingError: nil))"))
		}

		// when
		_ = await store.send(.view(.errorAlertDismissButtonTapped)) {
			// then
			$0.errorAlert = nil
		}

		await testScheduler.run() // fast-forward scheduler to the end of time
		await viewTask.cancel()
	}
}
