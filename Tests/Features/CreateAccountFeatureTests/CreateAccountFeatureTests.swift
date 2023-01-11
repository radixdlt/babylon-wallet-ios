import Collections
import ComposableArchitecture
@testable import CreateAccountFeature
import Cryptography
import JSON
import Prelude
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
		let newAccountName = "newAccount"
		let initialState = CreateAccount.State(shouldCreateProfile: true, isFirstAccount: true)
		let mnemonic = try Mnemonic(phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong", language: .english)
		let networkAndGateway = AppPreferences.NetworkAndGateway.nebunet
		let newProfile = try await Profile.new(networkAndGateway: networkAndGateway, mnemonic: mnemonic)
		let expectedCreateNewProfileRequest = CreateNewProfileRequest(
			networkAndGateway: networkAndGateway,
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

		// then

		// assert the proper flow is followed

		await store.receive(.internal(.system(.createdNewProfileResult(.success(newProfile)))))
		await store.receive(.internal(.system(.injectProfileIntoProfileClientResult(.success(newProfile)))))
		await store.receive(.internal(.system(.loadAccountResult(.success(.previewValue0))))) {
			$0.isCreatingAccount = false
		}
		await store.receive(.delegate(.createdNewAccount(account: .previewValue0, isFirstAccount: true)))

		// assert that clients are called with proper arguments

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
			// assert correct profile was stored in keychain
			let profileData = try! JSONEncoder.iso8601.encode(newProfile.snaphot())
			XCTAssertEqual($0["profileSnapshotKeychainKey"], profileData)

			// assert correct mnemonic was stored in keychain
			let newProfileReferenceId = newProfile.factorSources.curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources.first.reference.id
			XCTAssertEqual($0[newProfileReferenceId], mnemonic.entropy().data)
		}
	}

	func test__GIVEN__profile_exists__WHEN__new_account_button_tapped__THEN__new_account_is_created() async throws {
		// given
		let newAccountName = "newAccount"
		let isFirstAccount = false
		let initialState = CreateAccount.State()
		let expectedCreateAccountRequest = CreateAccountRequest(
			overridingNetworkID: nil,
			keychainAccessFactorSourcesAuthPrompt: L10n.CreateAccount.biometricsPrompt,
			accountName: newAccountName
		)
		let createdAccount = OnNetwork.Account.testValue

		let store = TestStore(
			initialState: initialState,
			reducer: CreateAccount()
		)

		store.dependencies.mainQueue = testScheduler.eraseToAnyScheduler()

		let createAccountRequest = ActorIsolated<CreateAccountRequest?>(nil)
		store.dependencies.profileClient.createVirtualAccount = { request in
			await createAccountRequest.setValue(request)
			return createdAccount
		}

		// when

		await store.send(.internal(.view(.textFieldChanged(newAccountName)))) {
			$0.inputtedAccountName = newAccountName
		}

		await store.send(.internal(.view(.createAccountButtonTapped))) {
			$0.isCreatingAccount = true
		}

		// then

		await store.receive(.internal(.system(.createdNewAccountResult(.success(createdAccount))))) {
			$0.isCreatingAccount = false
		}
		await store.receive(.delegate(.createdNewAccount(account: createdAccount, isFirstAccount: isFirstAccount)))

		await createAccountRequest.withValue { request in
			XCTAssertEqual(request, expectedCreateAccountRequest)
		}
	}

	func test__GIVEN__clients_failure__WHEN__creating_account__THEN__propagates_the_error() async throws {
		// given
		let initialState = CreateAccount.State()
		let createNewAccountError = NSError.testValue(domain: "Create New Account Request")
		let createNewProfileError = NSError.testValue(domain: "Create New Profile Request")
		let loadAccountsError = NSError.testValue(domain: "Load Accounts Request")
		let injectProfileError = NSError.testValue(domain: "Inject Profile Request")

		let expectedErrors = Set([createNewAccountError, createNewProfileError, loadAccountsError, injectProfileError])

		let store = TestStore(
			initialState: initialState,
			reducer: CreateAccount()
		)

		let errorQueue = ActorIsolated<Set<NSError>>([])
		store.dependencies.errorQueue.schedule = { error in
			Task {
				await errorQueue.withValue { queue in
					queue.insert(error as NSError)
				}
			}
		}

		// when

		await store.send(.internal(.system(.createdNewAccountResult(.failure(createNewAccountError)))))
		await store.send(.internal(.system(.createdNewProfileResult(.failure(createNewProfileError)))))
		await store.send(.internal(.system(.loadAccountResult(.failure(loadAccountsError)))))
		await store.send(.internal(.system(.injectProfileIntoProfileClientResult(.failure(injectProfileError)))))

		// then

		await errorQueue.withValue { errors in
			XCTAssertEqual(errors, expectedErrors)
		}
	}
}
