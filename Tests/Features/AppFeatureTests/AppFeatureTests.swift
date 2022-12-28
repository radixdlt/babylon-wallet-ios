@testable import AppFeature
import Collections
import ComposableArchitecture
import NonEmpty
import OnboardingFeature
import Profile
import ProfileClient
import ProfileLoader
@testable import SplashFeature
import TestUtils

@MainActor
final class AppFeatureTests: TestCase {
	let networkID = NetworkID.nebunet

	func test_initialAppState_whenAppLaunches_thenInitialAppStateIsSplash() {
		let appState = App.State()
		XCTAssertEqual(appState.root, .splash(.init()))
		XCTAssertNil(appState.errorAlert)
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
			$0.root = .onboarding(.init())
		}
	}

	func test_onboaring__GIVEN__no_profile__WHEN__new_profile_created__THEN__it_is_injected_into_profileClient_and_we_navigate_to_create_account_completion() async throws {
		// given
		let store = TestStore(
			initialState: App.State(root: .onboarding(.init(root: .createAccount(.init(shouldCreateProfile: true))))),
			reducer: App()
		)

		var profileClient: ProfileClient = .testValue
		profileClient.getAccounts = {
			let accounts: [OnNetwork.Account] = [.previewValue0]
			return NonEmpty(rawValue: OrderedSet(accounts))!
		}
		store.dependencies.profileClient = profileClient

		let newProfile = try await Profile.new(networkAndGateway: .nebunet, mnemonic: .generate())
		let expectation = expectation(description: "Profile injected")
		store.dependencies.profileClient.injectProfile = { injected in
			XCTAssertEqual(injected, newProfile)
			expectation.fulfill()
		}

		// when
		await store.send(.child(.onboarding(.createAccount(.delegate(.createdNewProfile(newProfile))))))

		// then
		await store.receive(.internal(.system(.injectProfileIntoProfileClientResult(.success(newProfile), createdNewProfile: true))))

		let account = try! await profileClient.getAccounts().first

		await store.receive(.child(.onboarding(.createAccount(.delegate(.displayCreateAccountCompletion(account, isFirstAccount: true, destination: .home)))))) {
			$0.root = .onboarding(.init(root: .createAccount(.init(
				shouldCreateProfile: true,
				accountCompletion: .init(
					account: account,
					isFirstAccount: true,
					destination: .home
				)
			))))
		}

		wait(for: [expectation], timeout: 0)
	}

	func test_splash__GIVEN__an_existing_profile__WHEN__existing_profile_loaded__THEN__it_is_injected_into_profileClient_and_we_navigate_to_main() async throws {
		// GIVEN: an existing profile
		let existingProfile = try await Profile.new(
			networkAndGateway: .nebunet,
			mnemonic: .generate()
		)

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
		await store.send(.child(.splash(.internal(.system(.loadProfileResult(
			.success(existingProfile)
		)))))) {
			$0.root = .splash(.init(alert: nil, profileResult: .success(existingProfile)))
		}

		await testScheduler.advance(by: .seconds(2))
		await store.receive(.child(.splash(.internal(.system(.biometricsConfigResult(.success(.biometricsAndPasscodeSetUp)))))))

		// then
		await store.receive(.child(.splash(.delegate(.profileResultLoaded(.success(existingProfile))))))

		await store.receive(.internal(.system(.injectProfileIntoProfileClientResult(.success(existingProfile), createdNewProfile: false)))) {
			$0.root = .main(.init())
		}

		await testScheduler.run() // fast-forward scheduler to the end of time

		wait(for: [expectation], timeout: 0)
	}

	func test__GIVEN__splash__WHEN__loadProfile_results_in_noProfile__THEN__navigate_to_onboarding() async {
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
		await store.send(.child(.splash(.internal(.system(.loadProfileResult(.success(nil))))))) {
			$0.root = .splash(.init(alert: nil, profileResult: .success(nil)))
		}

		await testScheduler.advance(by: .seconds(2))
		await store.receive(.child(.splash(.internal(.system(.biometricsConfigResult(.success(.biometricsAndPasscodeSetUp)))))))

		// then
		await store.receive(.child(.splash(.delegate(.profileResultLoaded(.success(nil)))))) {
			$0.root = .onboarding(.init())
		}

		await testScheduler.run() // fast-forward scheduler to the end of time
		await viewTask.cancel()
	}

	func test__GIVEN__splash__WHEN__loadProfile_results_in_decodingError__THEN__display_errorAlert_and_navigate_to_onboarding() async throws {
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
		let error = ProfileLoader.JSONDecodingError.KnownDecodingError(decodingError: decodingError)
		let foobar: ProfileLoader.JSONDecodingError = .known(error)
		let failure: ProfileLoader.ProfileLoadingFailure = .decodingFailure(
			json: "".data(using: .utf8)!,
			foobar
		)
		let result: ProfileLoader.ProfileResult = .failure(
			failure
		)
		await store.send(.child(.splash(.internal(.system(.loadProfileResult(
			result
		)))))) {
			$0.root = .splash(.init(alert: nil, profileResult: result))
		}

		await testScheduler.advance(by: .seconds(2))
		await store.receive(.child(.splash(.internal(.system(.biometricsConfigResult(.success(.biometricsAndPasscodeSetUp)))))))

		// then
		await store.receive(.child(.splash(.delegate(.profileResultLoaded(result))))) {
			$0.root = .onboarding(.init())
		}

		await store.receive(.internal(.system(.displayErrorAlert(
			App.UserFacingError(foobar)
		)))) {
			$0.errorAlert = .init(
				title: .init("An Error Occurred"),
				message: .init("Failed to create Wallet from backup: valueNotFound(Profile.Profile, Swift.DecodingError.Context(codingPath: [], debugDescription: \"Something went wrong\", underlyingError: nil))")
			)
		}

		await store.send(.view(.errorAlertDismissButtonTapped)) {
			// then
			$0.errorAlert = nil
		}

		await testScheduler.run() // fast-forward scheduler to the end of time
		await viewTask.cancel()
	}

	func test__GIVEN__splash__WHEN__loadProfile_results_in_failedToCreateProfileFromSnapshot__THEN__display_errorAlert_when_user_proceeds_incompatible_profile_is_deleted_from_keychain_and_navigate_to_onboarding() async throws {
		// given
		let store = TestStore(
			initialState: App.State(root: .splash(.init())),
			reducer: App()
		)

		let testScheduler = DispatchQueue.test

		store.dependencies.errorQueue = .liveValue
		store.dependencies.mainQueue = testScheduler.eraseToAnyScheduler()
		store.dependencies.keychainClient.removeDataForKey = { key in
			XCTAssertEqual(key, "profileSnapshotKeychainKey")
		}

		let viewTask = await store.send(.view(.task))

		// when
		struct SomeError: Swift.Error {}
		let badVersion: ProfileSnapshot.Version = .init(rawValue: .init(0, 0, 0))
		let failedToCreateProfileFromSnapshot = ProfileLoader.FailedToCreateProfileFromSnapshot(version: badVersion, error: SomeError())
		let result = ProfileLoader.ProfileResult.failure(.failedToCreateProfileFromSnapshot(failedToCreateProfileFromSnapshot))
		await store.send(.child(.splash(.internal(.system(.loadProfileResult(
			result
		)))))) {
			$0.root = .splash(.init(alert: nil, profileResult: result))
		}

		await testScheduler.advance(by: .seconds(2))
		await store.receive(.child(.splash(.internal(.system(.biometricsConfigResult(.success(.biometricsAndPasscodeSetUp)))))))

		await store.receive(.child(.splash(.delegate(.profileResultLoaded(result))))) {
			$0.errorAlert = .init(
				title: .init("Wallet Data is Incompatible"),
				message: .init("For this Preview wallet version, you must delete your wallet data to continue."),
				dismissButton: .destructive(.init("Delete Wallet Data"), action: .send(App.Action.ViewAction.deleteIncompatibleProfile))
			)
		}

		await store.send(.view(.deleteIncompatibleProfile))
		await store.receive(.internal(.system(.deletedIncompatibleProfile))) {
			$0.root = .onboarding(.init())
		}

		await testScheduler.run() // fast-forward scheduler to the end of time
		await viewTask.cancel()
	}

	func test__GIVEN__splash__WHEN__loadProfile_results_in_profileVersionOutdated__THEN__display_errorAlert_when_user_proceeds_incompatible_profile_is_deleted_from_keychain_and_navigate_to_onboarding() async throws {
		// given
		let store = TestStore(
			initialState: App.State(root: .splash(.init())),
			reducer: App()
		)

		let testScheduler = DispatchQueue.test

		store.dependencies.errorQueue = .liveValue
		store.dependencies.mainQueue = testScheduler.eraseToAnyScheduler()
		store.dependencies.keychainClient.removeDataForKey = { key in
			XCTAssertEqual(key, "profileSnapshotKeychainKey")
		}

		let viewTask = await store.send(.view(.task))

		// when
		struct SomeError: Swift.Error {}
		let badVersion: ProfileSnapshot.Version = .init(rawValue: .init(0, 0, 0))
		let result = ProfileLoader.ProfileResult.failure(.profileVersionOutdated(json: Data([0xDE, 0xAD]), version: badVersion))
		await store.send(.child(.splash(.internal(.system(.loadProfileResult(
			result
		)))))) {
			$0.root = .splash(.init(alert: nil, profileResult: result))
		}

		await testScheduler.advance(by: .seconds(2))
		await store.receive(.child(.splash(.internal(.system(.biometricsConfigResult(.success(.biometricsAndPasscodeSetUp)))))))

		await store.receive(.child(.splash(.delegate(.profileResultLoaded(result))))) {
			$0.errorAlert = .init(
				title: .init("Wallet Data is Incompatible"),
				message: .init("For this Preview wallet version, you must delete your wallet data to continue."),
				dismissButton: .destructive(.init("Delete Wallet Data"), action: .send(App.Action.ViewAction.deleteIncompatibleProfile))
			)
		}

		await store.send(.view(.deleteIncompatibleProfile))
		await store.receive(.internal(.system(.deletedIncompatibleProfile))) {
			$0.root = .onboarding(.init())
		}

		await testScheduler.run() // fast-forward scheduler to the end of time
		await viewTask.cancel()
	}
}
