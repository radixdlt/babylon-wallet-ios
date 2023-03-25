@testable import DappInteractionFeature
import FeatureTestingPrelude

@MainActor
final class ChooseAccountsTests: TestCase {
	let interactionItem: DappInteractionFlow.State.AnyInteractionItem = .local(.accountPermissionRequested(.exactly(2)))

	func test_continueFromChooseAccounts_whenTappedOnContinue_thenFinishAccountSelection() async {
		// given
		var singleAccount = ChooseAccountsRow.State.previewValueOne
		singleAccount.isSelected = true
		let store = TestStore(
			initialState: ChooseAccounts.State(
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
		await store.receive(.delegate(.continueButtonTapped(expectedAccounts, .oneTime)))
	}

	func test_didSelectAccount_whenTappedOnSelectedAccount_thenDeselectThatAccount() async {
		// given
		var accountRow = ChooseAccountsRow.State.previewValueOne
		accountRow.isSelected = true

		let initialState: ChooseAccounts.State = .init(
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
		await store.send(.child(.account(id: accountRow.id, action: .view(.didSelect))))

		// then
		await store.receive(.child(.account(id: accountRow.id, action: .delegate(.didSelect)))) {
			$0.availableAccounts[id: accountRow.id]?.isSelected = false
		}
	}

	func test_didSelectAccount_whenTappedOnDeselectedAccount_thenSelectThatAccount_ifMustSelectAtLeastOneAccount() async {
		// given
		var accountRowOne = ChooseAccountsRow.State.previewValueOne
		accountRowOne.isSelected = false

		var accountRowTwo = ChooseAccountsRow.State.previewValueTwo
		accountRowTwo.isSelected = false

		let initialState: ChooseAccounts.State = .init(
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
		await store.send(.child(.account(id: accountRowOne.id, action: .view(.didSelect))))
		await store.receive(.child(.account(id: accountRowOne.id, action: .delegate(.didSelect)))) {
			// then
			$0.availableAccounts[id: accountRowOne.id]?.isSelected = true
		}

		// then
		await store.send(.child(.account(id: accountRowTwo.id, action: .view(.didSelect))))
		await store.receive(.child(.account(id: accountRowTwo.id, action: .delegate(.didSelect)))) {
			// then
			$0.availableAccounts[id: accountRowTwo.id]?.isSelected = true
		}
	}

	func test_didSelectAccount_whenTappedOnDeselectedAccount_thenSelectThatAccount_ifNotOverSelectedAccountLimit() async {
		// given
		var accountRow = ChooseAccountsRow.State.previewValueOne
		accountRow.isSelected = false

		let initialState: ChooseAccounts.State = .init(
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
		await store.send(.child(.account(id: accountRow.id, action: .view(.didSelect))))

		// then
		await store.receive(.child(.account(id: accountRow.id, action: .delegate(.didSelect)))) {
			$0.availableAccounts[id: accountRow.id]?.isSelected = true
		}
	}

	func test_didSelectAccount_whenTappedOnDeselectedAccount_thenSelectThatAccountInstead_ifAccountLimitOfOne() async {
		// given
		var accountRowOne = ChooseAccountsRow.State.previewValueOne
		accountRowOne.isSelected = true

		var accountRowTwo = ChooseAccountsRow.State.previewValueTwo
		accountRowTwo.isSelected = false

		let initialState: ChooseAccounts.State = .init(
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
		await store.receive(.child(.account(id: accountRowTwo.id, action: .delegate(.didSelect)))) {
			$0.availableAccounts[id: accountRowOne.id]?.isSelected = false
			$0.availableAccounts[id: accountRowTwo.id]?.isSelected = true
		}
	}
}
