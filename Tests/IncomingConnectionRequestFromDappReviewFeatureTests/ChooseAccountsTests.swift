import ComposableArchitecture
@testable import IncomingConnectionRequestFromDappReviewFeature
import TestUtils

@MainActor
final class ChooseAccountsTests: TestCase {
	func test_continueFromChooseAccounts_whenTappedOnContinue_thenCoordinateToNextScreen() async {
		// given
		let store = TestStore(
			initialState: ChooseAccounts.State.placeholder,
			reducer: ChooseAccounts()
		)

		// when
		_ = await store.send(.internal(.user(.continueFromChooseAccounts)))

		// then
		_ = await store.receive(.coordinate(.continueFromChooseAccounts))
	}

	func test_dismissChooseAccounts_whenTappedOnDismiss_thenCoordinateDismissal() async {
		// given
		let store = TestStore(
			initialState: ChooseAccounts.State.placeholder,
			reducer: ChooseAccounts()
		)

		// when
		_ = await store.send(.internal(.user(.dismissChooseAccounts)))

		// then
		_ = await store.receive(.coordinate(.dismissChooseAccounts))
	}

	func test_didSelectAccount_whenTappedOnSelectedAccount_thenDeselectThatAccount() async {
		// given
		var accountRow = ChooseAccounts.Row.State.placeholder
		accountRow.isSelected = true

		let connectionRequest: IncomingConnectionRequestFromDapp = .init(
			componentAddress: "deadbeef",
			name: "Radaswap",
			permissions: [],
			accountLimit: 1
		)

		let initialState: ChooseAccounts.State = .init(
			incomingConnectionRequestFromDapp: connectionRequest,
			canProceed: false,
			accounts: .init(
				uniqueElements: [
					accountRow,
				]
			)
		)

		let store = TestStore(
			initialState: initialState,
			reducer: ChooseAccounts()
		)

		// when
		_ = await store.send(.account(id: accountRow.id, action: .internal(.user(.didSelect)))) {
			// then
			$0.accounts[id: accountRow.id]?.isSelected = false
			$0.canProceed = false
		}
	}

	func test_didSelectAccount_whenTappedOnDeselectedAccount_thenSelectThatAccount_ifNotOverSelectedAccountLimit() async {
		// given
		var accountRow = ChooseAccounts.Row.State.placeholder
		accountRow.isSelected = false

		let connectionRequest: IncomingConnectionRequestFromDapp = .init(
			componentAddress: "deadbeef",
			name: "Radaswap",
			permissions: [],
			accountLimit: 1
		)

		let initialState: ChooseAccounts.State = .init(
			incomingConnectionRequestFromDapp: connectionRequest,
			canProceed: false,
			accounts: .init(
				uniqueElements: [
					accountRow,
				]
			)
		)

		let store = TestStore(
			initialState: initialState,
			reducer: ChooseAccounts()
		)

		// when
		_ = await store.send(.account(id: accountRow.id, action: .internal(.user(.didSelect)))) {
			// then
			$0.accounts[id: accountRow.id]?.isSelected = true
			$0.canProceed = true
		}
	}

	func test_didSelectAccount_whenTappedOnDeselectedAccount_thenDontSelectThatAccount_ifOverSelectedAccountLimit() async {
		// given
		var accountRow = ChooseAccounts.Row.State.placeholder
		accountRow.isSelected = false

		let connectionRequest: IncomingConnectionRequestFromDapp = .init(
			componentAddress: "deadbeef",
			name: "Radaswap",
			permissions: [],
			accountLimit: 0
		)

		let initialState: ChooseAccounts.State = .init(
			incomingConnectionRequestFromDapp: connectionRequest,
			canProceed: false,
			accounts: .init(
				uniqueElements: [
					accountRow,
				]
			)
		)

		let store = TestStore(
			initialState: initialState,
			reducer: ChooseAccounts()
		)

		// when
		_ = await store.send(.account(id: accountRow.id, action: .internal(.user(.didSelect))))

		// then
		// no state change should occur
	}
}
