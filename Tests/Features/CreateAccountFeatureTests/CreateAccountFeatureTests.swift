import Collections
import ComposableArchitecture
@testable import CreateAccountFeature
import JSON
import KeychainClient
import Mnemonic
import NonEmpty
import Profile
import ProfileClient
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

	func test_viewDidAppear_whenViewAppears_thenChecksIfFirstAccountAndFocusOnTextFieldAfterDelay() async {
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

		let isFirstAccount = true
		let didCheckIfHasAccountOnNetwork = ActorIsolated<NetworkID?>(nil)
		store.dependencies.profileClient.hasAccountOnNetwork = { networkID in
			await didCheckIfHasAccountOnNetwork.setValue(networkID)
			return !isFirstAccount
		}
		store.dependencies.mainQueue = testScheduler.eraseToAnyScheduler()

		// when
		await store.send(.internal(.view(.viewAppeared)))

		// then
		await store.receive(.internal(.system(.hasAccountOnNetworkResult(.success(!isFirstAccount))))) {
			$0.isFirstAccount = isFirstAccount
		}
		await testScheduler.advance(by: .seconds(0.5))
		await store.receive(.internal(.system(.focusTextField(.accountName)))) {
			$0.focusedField = .accountName
		}
		await testScheduler.run() // fast-forward scheduler to the end of time

		await didCheckIfHasAccountOnNetwork.withValue {
			XCTAssertEqual($0, .some(initialState.networkAndGateway.network.id))
		}
	}

	func test__GIVEN__no_profile__WHEN__new_profile_button_tapped__THEN__user_is_onboarded_with_new_profile() async throws {
		// given
		let newAccountName = "newAccount"
		let initialState = CreateAccount.State(shouldCreateProfile: true)
		let mnemonic = try Mnemonic(phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong", language: .english)
		let newProfile = try await Profile.new(networkAndGateway: initialState.networkAndGateway, mnemonic: mnemonic)
		let expectedCreateNewProfileRequest = CreateNewProfileRequest(
			networkAndGateway: initialState.networkAndGateway,
			curve25519FactorSourceMnemonic: mnemonic,
			nameOfFirstAccount: newAccountName
		)

		let store = TestStore(
			initialState: initialState,
			reducer: CreateAccount()
		)

		let generateMnemonicCalled = ActorIsolated<(wordCount: BIP39.WordCount, language: BIP39.Language)?>(nil)
		store.dependencies.mnemonicGenerator.generate = { wordCount, language in
			Task {
				await generateMnemonicCalled.setValue((wordCount, language))
			}
			return mnemonic
		}

		let createNewProfileRequest = ActorIsolated<CreateNewProfileRequest?>(nil)
		store.dependencies.profileClient.createNewProfile = { req in
			await createNewProfileRequest.setValue(req)
			return newProfile
		}

		let keychainUpdateData = ActorIsolated<[String: Data]>([:])
		store.dependencies.keychainClient.updateDataForKey = { data, key, _, _ in
			await keychainUpdateData.withValue {
				$0[key] = data
			}
		}

		let injectedProfile = ActorIsolated<Profile?>(nil)
		store.dependencies.profileClient.injectProfile = { injected in
			await injectedProfile.setValue(injected)
		}

		store.dependencies.profileClient.getAccounts = {
			let accounts: [OnNetwork.Account] = [.previewValue0]
			return NonEmpty(rawValue: OrderedSet(accounts))!
		}

		// when
		await store.send(.internal(.view(.textFieldChanged(newAccountName)))) {
			$0.inputtedAccountName = newAccountName
		}

		await store.send(.internal(.view(.createAccountButtonTapped))) {
			$0.isCreatingAccount = true
		}

		await store.receive(.internal(.system(.createdNewProfileResult(.success(newProfile))))) {
			$0.isCreatingAccount = false
		}

		await store.receive(.internal(.system(.injectProfileIntoProfileClientResult(.success(newProfile)))))
		await store.receive(.internal(.system(.loadAccountResult(.success(.previewValue0)))))
		await store.receive(.delegate(.createdNewAccount(account: .previewValue0, isFirstAccount: true)))

		// then
		await generateMnemonicCalled.withValue {
			XCTAssertEqual($0?.wordCount, .twentyFour)
			XCTAssertEqual($0?.language, .english)
		}

		await createNewProfileRequest.withValue {
			XCTAssertEqual($0?.networkAndGateway, expectedCreateNewProfileRequest.networkAndGateway)
			XCTAssertEqual($0?.curve25519FactorSourceMnemonic, expectedCreateNewProfileRequest.curve25519FactorSourceMnemonic)
			XCTAssertEqual($0?.nameOfFirstAccount, expectedCreateNewProfileRequest.nameOfFirstAccount)
		}

		await keychainUpdateData.withValue {
			let profileData = try! JSONEncoder.iso8601.encode(newProfile.snaphot())
			XCTAssertEqual($0["profileSnapshotKeychainKey"], profileData)

			let newProfileReferenceId = newProfile.factorSources.curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources.first.reference.id

			XCTAssertEqual($0[newProfileReferenceId], mnemonic.entropy().data)
		}
	}
}
