import ComposableArchitecture
@testable import CreateAccountFeature
import TestUtils

@MainActor
final class CreateAccountFeatureTests: TestCase {
	let testScheduler = DispatchQueue.test

	func test_closeButtonTapped_whenTappedOnCloseButton_thenCoordinateDismissal() async {
		// given
		let initialState = CreateAccount.State()
		let store = TestStore(
			initialState: initialState,
			reducer: CreateAccount()
		)

		// when
		_ = await store.send(.internal(.user(.closeButtonTapped)))

		// then
		await store.receive(.coordinate(.dismissCreateAccount))
	}

	func test_textFieldDidChange_whenUserEntersValidAccountName_thenUpdateState() async {
		// given
		let initialState = CreateAccount.State(
			accountName: "",
			isValid: false,
			focusedField: nil
		)
		let store = TestStore(
			initialState: initialState,
			reducer: CreateAccount()
				.dependency(\.accountNameValidator, .liveValue)
		)
		let accountName = "My account"

		// when
		_ = await store.send(.internal(.user(.textFieldDidChange(accountName)))) {
			// then
			$0.isValid = true
			$0.accountName = accountName
		}
	}

	func test_textFieldDidChange_whenUserEntersTooLongAccountName_thenDoNothing() async {
		// given
		var accountName = "My account dummy nam" // character count == 20
		let initialState = CreateAccount.State(
			accountName: accountName,
			isValid: true,
			focusedField: .accountName
		)
		let store = TestStore(
			initialState: initialState,
			reducer: CreateAccount()
				.dependency(\.accountNameValidator, .liveValue)
		)
		accountName = "My account dummy name" // character count == 21, over the limit

		// when
		_ = await store.send(.internal(.user(.textFieldDidChange(accountName))))
		// then
		// no state change occured
	}

	func test_viewDidAppear_whenViewAppears_thenFocusOnTextFieldAfterDelay() async {
		// given
		let initialState = CreateAccount.State(
			accountName: "",
			isValid: false,
			focusedField: nil
		)
		let store = TestStore(
			initialState: initialState,
			reducer: CreateAccount()
		)

		store.dependencies.mainQueue = testScheduler.eraseToAnyScheduler()

		// when
		_ = await store.send(.internal(.system(.viewDidAppear)))

		// then
		await testScheduler.advance(by: .seconds(0.5))
		await store.receive(.internal(.system(.focusTextField))) {
			$0.focusedField = .accountName
		}
	}
}
