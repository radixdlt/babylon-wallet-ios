@testable import DappInteractionFeature
import FeatureTestingPrelude

@MainActor
final class ChooseAccountsTests: TestCase {
	let interactionItem: DappInteractionFlow.State.AnyInteractionItem = .local(.permissionRequested(.accounts(.exactly(2))))

	func test_continueFromChooseAccounts_whenTappedOnContinue_thenFinishAccountSelection() async {
		// given
		var singleAccount = ChooseAccounts.Row.State.previewValueOne
		singleAccount.isSelected = true
		let store = TestStore(
			initialState: ChooseAccounts.State(
				interactionItem: interactionItem,
				accessKind: .oneTime,
				dappDefinitionAddress: try! .init(address: "account_deadbeef"),
				dappMetadata: .init(name: "Dapp name", description: "A description"),
				numberOfAccounts: .exactly(1),
				availableAccounts: [
					singleAccount,
				]
			),
			reducer: ChooseAccounts()
		)

		// when
		await store.send(.view(.continueButtonTapped))

		// then
		let expectedAccounts = IdentifiedArrayOf(uniqueElements: [singleAccount.account])
		await store.receive(.delegate(.continueButtonTapped(interactionItem, expectedAccounts)))
	}

	func test_dismissChooseAccounts_whenTappedOnDismiss_thenCoordinateDismissal() async {
		// given
		let store = TestStore(
			initialState: ChooseAccounts.State(
				interactionItem: interactionItem,
				accessKind: .oneTime,
				dappDefinitionAddress: try! .init(address: "account_deadbeef"),
				dappMetadata: .init(name: "Dapp name", description: "A description"),
				numberOfAccounts: .exactly(1)
			),
			reducer: ChooseAccounts()
		)

		// when
		await store.send(.view(.dismissButtonTapped))

		// then
		await store.receive(.delegate(.dismissButtonTapped))
	}

	func test_didSelectAccount_whenTappedOnSelectedAccount_thenDeselectThatAccount() async {
		// given
		var accountRow = ChooseAccounts.Row.State.previewValueOne
		accountRow.isSelected = true

		let initialState: ChooseAccounts.State = .init(
			interactionItem: interactionItem,
			accessKind: .oneTime,
			dappDefinitionAddress: try! .init(address: "account_deadbeef"),
			dappMetadata: .init(name: "Dapp name", description: "A description"),
			numberOfAccounts: .exactly(1),
			availableAccounts: .init(
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
			$0.availableAccounts[id: accountRow.id]?.isSelected = false
		}
	}

	func test_didSelectAccount_whenTappedOnDeselectedAccount_thenSelectThatAccount_ifMustSelectAtLeastOneAccount() async {
		// given
		var accountRowOne = ChooseAccounts.Row.State.previewValueOne
		accountRowOne.isSelected = false

		var accountRowTwo = ChooseAccounts.Row.State.previewValueTwo
		accountRowTwo.isSelected = false

		let initialState: ChooseAccounts.State = .init(
			interactionItem: interactionItem,
			accessKind: .oneTime,
			dappDefinitionAddress: try! .init(address: "account_deadbeef"),
			dappMetadata: .init(name: "Dapp name", description: "A description"),
			numberOfAccounts: .atLeast(1),
			availableAccounts: .init(
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
			$0.availableAccounts[id: accountRowOne.id]?.isSelected = true
		}

		// when
		await store.send(.child(.account(id: accountRowTwo.id, action: .view(.didSelect)))) {
			// then
			$0.availableAccounts[id: accountRowTwo.id]?.isSelected = true
		}
	}

	func test_didSelectAccount_whenTappedOnDeselectedAccount_thenSelectThatAccount_ifNotOverSelectedAccountLimit() async {
		// given
		var accountRow = ChooseAccounts.Row.State.previewValueOne
		accountRow.isSelected = false

		let initialState: ChooseAccounts.State = .init(
			interactionItem: interactionItem,
			accessKind: .oneTime,
			dappDefinitionAddress: try! .init(address: "account_deadbeef"),
			dappMetadata: .init(name: "Dapp name", description: "A description"),
			numberOfAccounts: .exactly(1),
			availableAccounts: .init(
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
			$0.availableAccounts[id: accountRow.id]?.isSelected = true
		}
	}

	func test_didSelectAccount_whenTappedOnDeselectedAccount_thenDontSelectThatAccount_ifOverSelectedAccountLimit() async {
		// given
		var accountRowOne = ChooseAccounts.Row.State.previewValueOne
		accountRowOne.isSelected = true

		var accountRowTwo = ChooseAccounts.Row.State.previewValueTwo
		accountRowTwo.isSelected = false

		let initialState: ChooseAccounts.State = .init(
			interactionItem: interactionItem,
			accessKind: .oneTime,
			dappDefinitionAddress: try! .init(address: "account_deadbeef"),
			dappMetadata: .init(name: "Dapp name", description: "A description"),
			numberOfAccounts: .exactly(1),
			availableAccounts: .init(
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
