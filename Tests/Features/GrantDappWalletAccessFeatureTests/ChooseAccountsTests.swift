@testable import DappInteractionFeature
import FeatureTestingPrelude

@MainActor
final class ChooseAccountsTests: TestCase {
	func test_continueFromChooseAccounts_whenTappedOnContinue_thenFinishAccountSelection() async {
		// given
		let requestItem: P2P.OneTimeAccountsRequestToHandle = .init(
			requestItem: .init(numberOfAccounts: .exactly(1), requiresProofOfOwnership: false),
			parentRequest: .previewValue
		)
		var singleAccount = ChooseAccounts.Row.State.previewValueOne
		singleAccount.isSelected = true
		let store = TestStore(
			initialState: ChooseAccounts.State(
				request: requestItem,
				accounts: [
					singleAccount,
				]
			),
			reducer: ChooseAccounts()
		)

		// when
		await store.send(.view(.continueButtonTapped))

		// then
		let expectedAccounts = NonEmpty(rawValue: IdentifiedArrayOf(uniqueElements: [singleAccount.account]))!
		await store.receive(.delegate(.finishedChoosingAccounts(expectedAccounts, requestItem)))
	}

	func test_dismissChooseAccounts_whenTappedOnDismiss_thenCoordinateDismissal() async {
		// given
		let requestItem: P2P.OneTimeAccountsRequestToHandle = .init(
			requestItem: .init(numberOfAccounts: .exactly(1), requiresProofOfOwnership: false),
			parentRequest: .previewValue
		)
		let store = TestStore(
			initialState: ChooseAccounts.State(request: requestItem),
			reducer: ChooseAccounts()
		)

		// when
		await store.send(.view(.dismissButtonTapped))

		// then
		await store.receive(.delegate(.dismissChooseAccounts(requestItem)))
	}

	func test_didSelectAccount_whenTappedOnSelectedAccount_thenDeselectThatAccount() async {
		// given
		var accountRow = ChooseAccounts.Row.State.previewValueOne
		accountRow.isSelected = true

		let initialState: ChooseAccounts.State = .init(
			request: .init(
				requestItem: .init(numberOfAccounts: .exactly(1), requiresProofOfOwnership: false),
				parentRequest: .previewValue
			),
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
		await store.send(.child(.account(id: accountRow.id, action: .view(.didSelect)))) {
			// then
			$0.accounts[id: accountRow.id]?.isSelected = false
		}
	}

	func test_didSelectAccount_whenTappedOnDeselectedAccount_thenSelectThatAccount_ifMustSelectAtLeastOneAccount() async {
		// given
		var accountRowOne = ChooseAccounts.Row.State.previewValueOne
		accountRowOne.isSelected = false

		var accountRowTwo = ChooseAccounts.Row.State.previewValueTwo
		accountRowTwo.isSelected = false

		let initialState: ChooseAccounts.State = .init(
			request: .init(
				requestItem: .init(numberOfAccounts: .atLeast(1), requiresProofOfOwnership: false),
				parentRequest: .previewValue
			),
			accounts: .init(
				uniqueElements: [
					accountRowOne,
					accountRowTwo,
				]
			)
		)

		let store = TestStore(
			initialState: initialState,
			reducer: ChooseAccounts()
		)

		// when
		await store.send(.child(.account(id: accountRowOne.id, action: .view(.didSelect)))) {
			// then
			$0.accounts[id: accountRowOne.id]?.isSelected = true
		}

		// when
		await store.send(.child(.account(id: accountRowTwo.id, action: .view(.didSelect)))) {
			// then
			$0.accounts[id: accountRowTwo.id]?.isSelected = true
		}
	}

	func test_didSelectAccount_whenTappedOnDeselectedAccount_thenSelectThatAccount_ifNotOverSelectedAccountLimit() async {
		// given
		var accountRow = ChooseAccounts.Row.State.previewValueOne
		accountRow.isSelected = false

		let initialState: ChooseAccounts.State = .init(
			request: .init(
				requestItem: .init(numberOfAccounts: .exactly(1), requiresProofOfOwnership: false),
				parentRequest: .previewValue
			),
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
		await store.send(.child(.account(id: accountRow.id, action: .view(.didSelect)))) {
			// then
			$0.accounts[id: accountRow.id]?.isSelected = true
		}
	}

	func test_didSelectAccount_whenTappedOnDeselectedAccount_thenDontSelectThatAccount_ifOverSelectedAccountLimit() async {
		// given
		var accountRowOne = ChooseAccounts.Row.State.previewValueOne
		accountRowOne.isSelected = true

		var accountRowTwo = ChooseAccounts.Row.State.previewValueTwo
		accountRowTwo.isSelected = false

		let initialState: ChooseAccounts.State = .init(
			request: .init(
				requestItem: .init(numberOfAccounts: .exactly(1), requiresProofOfOwnership: false),
				parentRequest: .previewValue
			),
			accounts: .init(
				uniqueElements: [
					accountRowOne,
					accountRowTwo,
				]
			)
		)

		let store = TestStore(
			initialState: initialState,
			reducer: ChooseAccounts()
		)

		// when
		await store.send(.child(.account(id: accountRowTwo.id, action: .view(.didSelect))))

		// then
		// no state change should occur
	}
}
