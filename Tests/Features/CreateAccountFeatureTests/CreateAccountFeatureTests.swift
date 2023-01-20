@testable import CreateAccountFeature
import Cryptography
import FeatureTestingPrelude
import ProfileClient

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
		// GIVEN no profile
		let initialState = CreateAccount.State(shouldCreateProfile: true, isFirstAccount: true)

		let newAccountName = "newAccount"
		let networkAndGateway = AppPreferences.NetworkAndGateway.nebunet
		let newProfile = try await Profile.new(networkAndGateway: networkAndGateway, mnemonic: .init())
		let accounts = try newProfile.onNetwork(id: networkAndGateway.network.id).accounts
		let account = accounts.first
		let expectedCreateNewProfileRequest = CreateNewProfileRequest(
			nameOfFirstAccount: newAccountName
		)

		let createNewProfileRequest = ActorIsolated<CreateNewProfileRequest?>(nil)

		let store = TestStore(
			initialState: initialState,
			reducer: CreateAccount()
		) {
			$0.profileClient.createNewProfile = { req in
				await createNewProfileRequest.setValue(req)
				return account
			}
			$0.profileClient.getAccounts = {
				accounts
			}
		}

		await store.send(.internal(.view(.textFieldChanged(newAccountName)))) {
			$0.inputtedAccountName = newAccountName
		}

		// WHEN create Account button is tapped
		await store.send(.internal(.view(.createAccountButtonTapped))) {
			$0.isCreatingAccount = true
		}

		// THEN a new profile should be created
		await store.receive(.internal(.system(.createdNewAccountResult(.success(account))))) {
			$0.isCreatingAccount = false
		}
		await store.receive(.delegate(.createdNewAccount(account: account, isFirstAccount: true)))

		await createNewProfileRequest.withValue {
			XCTAssertEqual($0?.nameOfFirstAccount, expectedCreateNewProfileRequest.nameOfFirstAccount)
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

		let createAccountRequest = ActorIsolated<CreateAccountRequest?>(nil)
		let addedAccount = ActorIsolated<OnNetwork.Account?>(nil)

		let store = TestStore(
			initialState: initialState,
			reducer: CreateAccount()
		) {
			$0.profileClient.createUnsavedVirtualAccount = { request in
				await createAccountRequest.setValue(request)
				return createdAccount
			}
			$0.profileClient.addAccount = {
				await addedAccount.setValue($0)
			}
			$0.mainQueue = testScheduler.eraseToAnyScheduler()
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
		await addedAccount.withValue { account in
			XCTAssertEqual(account, createdAccount)
		}
	}

	func test__GIVEN__clients_failure__WHEN__creating_account__THEN__propagates_the_error() async throws {
		// given
		let initialState = CreateAccount.State()
		let createNewAccountError = NSError.testValue(domain: "Create New Account Request")

		let expectedErrors = Set([createNewAccountError])

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

		// then

		await errorQueue.withValue { errors in
			XCTAssertEqual(errors, expectedErrors)
		}
	}
}
