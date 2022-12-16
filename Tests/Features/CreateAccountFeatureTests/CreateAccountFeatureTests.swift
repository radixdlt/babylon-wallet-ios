import ComposableArchitecture
@testable import CreateAccountFeature
import JSON
import KeychainClient
import Mnemonic
import Profile
import TestUtils
import UserDefaultsClient

@MainActor
final class CreateAccountFeatureTests: TestCase {
	let testScheduler = DispatchQueue.test

	func test_closeButtonTapped_whenTappedOnCloseButton_thenCoordinateDismissal() async {
		// given
		let initialState = CreateAccount.State(shouldCreateProfile: false)
		let store = TestStore(
			initialState: initialState,
			reducer: CreateAccount()
		)

		// when
		await store.send(.internal(.view(.closeButtonTapped)))

		// then
		await store.receive(.delegate(.dismissCreateAccount))
	}

	func test_textFieldDidChange_whenUserEntersAccountName_thenUpdateState() async {
		// given
		let initialState = CreateAccount.State(
			shouldCreateProfile: false,
			inputtedAccountName: "",
			focusedField: nil
		)
		let store = TestStore(
			initialState: initialState,
			reducer: CreateAccount()
		)
		let inputtedAccountName = "My account"

		// when
		await store.send(.internal(.view(.textFieldChanged(inputtedAccountName)))) {
			// then
			$0.inputtedAccountName = inputtedAccountName
		}
	}

	func test_viewDidAppear_whenViewAppears_thenFocusOnTextFieldAfterDelay() async {
		// given
		let initialState = CreateAccount.State(
			shouldCreateProfile: false,
			inputtedAccountName: "",
			focusedField: nil
		)
		let store = TestStore(
			initialState: initialState,
			reducer: CreateAccount()
		)

		store.dependencies.mainQueue = testScheduler.eraseToAnyScheduler()

		// when
		await store.send(.internal(.view(.viewAppeared)))

		// then
		await testScheduler.advance(by: .seconds(0.5))
		await store.receive(.internal(.system(.focusTextField(.accountName)))) {
			$0.focusedField = .accountName
		}
		await testScheduler.run() // fast-forward scheduler to the end of time
	}

	func test__GIVEN__no_profile__WHEN__new_profile_button_tapped__THEN__user_is_onboarded_with_new_profile() async throws {
		// given
		var keychainClient: KeychainClient = .testValue

		let setDataForProfileSnapshotExpectation = expectation(description: "setDataForKey for ProfileSnapshot should have been called")
		let profileSavedToKeychain = ActorIsolated<Profile?>(nil)

		keychainClient.updateDataForKey = { data, key, _, _ in
			if key == "profileSnapshotKeychainKey" {
				if let snapshot = try? JSONDecoder.liveValue().decode(ProfileSnapshot.self, from: data) {
					let profile = try? Profile(snapshot: snapshot)
					Task {
						await profileSavedToKeychain.setValue(profile)
						setDataForProfileSnapshotExpectation.fulfill()
					}
				}
			}
		}

		let store = TestStore(
			initialState: CreateAccount.State(shouldCreateProfile: true),
			reducer: CreateAccount()
		)
		store.dependencies.profileClient.createNewProfile = { req in
			try! await Profile.new(
				networkAndGateway: req.networkAndGateway,
				mnemonic: req.curve25519FactorSourceMnemonic
			)
		}

		store.dependencies.keychainClient = keychainClient
		let mnemonic = try Mnemonic(phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong", language: .english)
		let generateMnemonicCalled = ActorIsolated<Bool>(false)

		let mnemonicGeneratorExpectation = expectation(description: "Generate Mnemonic should have been called")
		store.dependencies.mnemonicGenerator.generate = { _, _ in
			Task {
				await generateMnemonicCalled.setValue(true)
				mnemonicGeneratorExpectation.fulfill()
			}
			return mnemonic
		}

		// when
		await store.send(.internal(.view(.createAccountButtonTapped))) {
			$0.isCreatingAccount = true
		}

		// then
		await store.receive(.internal(.system(.createProfile)))

		waitForExpectations(timeout: 1)
		await profileSavedToKeychain.withValue {
			if let profile = $0 {
				await store.receive(.internal(.system(.createdNewProfileResult(.success(profile))))) {
					$0.isCreatingAccount = false
				}
				await store.receive(.delegate(.createdNewProfile(profile)))
			}
		}
		await generateMnemonicCalled.withValue {
			XCTAssertTrue($0)
		}
	}
}
