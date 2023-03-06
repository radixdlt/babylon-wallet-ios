@testable import CreateEntityFeature
import Cryptography
import FeatureTestingPrelude

@MainActor
final class NameNewEntityTests: TestCase {
	let testScheduler = DispatchQueue.test

	func test_textFieldDidChange_whenUserEntersAccountName_thenUpdateState() async {
		// given
		let initialState = NameNewEntity<OnNetwork.Account>.State(
			config: .init(
				//				isFirstEntity: true,
//				canBeDismissed: true,
//				navigationButtonCTA: .goHome
				purpose: .newAccountFromHome
			))

		let store = TestStore(
			initialState: initialState,
			reducer: NameNewEntity<OnNetwork.Account>()
		)
		let inputtedAccountName = "My account"
		// when
		await store.send(.view(.textFieldChanged(inputtedAccountName))) {
			// then
			$0.inputtedName = inputtedAccountName
			$0.sanitizedName = .init(rawValue: inputtedAccountName)
		}
	}

	func test__GIVEN__textFieldNotFocused__WHEN__viewDidAppear__THEN__textFieldGetsFocused() async {
		// given
		let initialState = NameNewEntity<OnNetwork.Account>.State(
			config: .init(
				purpose: .newAccountFromHome
			)
		)

		let clock = TestClock()
		let store = TestStore(
			initialState: initialState,
			reducer: NameNewEntity<OnNetwork.Account>()
		) {
			$0.continuousClock = clock
		}

		// when
		await store.send(.view(.appeared))

		// then
		await clock.advance(by: .seconds(0.5))
		await store.receive(.internal(.focusTextField(.entityName))) {
			$0.focusedField = .entityName
		}
		await testScheduler.run() // fast-forward scheduler to the end of time
	}
}
