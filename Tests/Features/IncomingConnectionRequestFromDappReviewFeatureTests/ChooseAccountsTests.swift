import Collections
import ComposableArchitecture
@testable import IncomingConnectionRequestFromDappReviewFeature
import NonEmpty
import Profile
import TestUtils

@MainActor
final class ChooseAccountsTests: TestCase {
	func test_continueFromChooseAccounts_whenTappedOnContinue_thenCoordinateToNextScreen() async {
		// given
		var singleAccount = ChooseAccounts.Row.State.placeholderOne
		singleAccount.isSelected = true
		let store = TestStore(
			initialState: ChooseAccounts.State(
				request: .init(
					requestItem: .placeholder,
					parentRequest: .placeholder
				),
				accounts: [
					singleAccount,
				]
			),
			reducer: ChooseAccounts()
		)

		// when
		await store.send(.view(.continueButtonTapped))

		// then
		let expectedAccounts = NonEmpty(rawValue: OrderedSet(uncheckedUniqueElements: [singleAccount.account]))!
		await store.receive(.delegate(.finishedChoosingAccounts(expectedAccounts)))
	}

	func test_dismissChooseAccounts_whenTappedOnDismiss_thenCoordinateDismissal() async {
		// given
		let store = TestStore(
			initialState: ChooseAccounts.State.placeholder,
			reducer: ChooseAccounts()
		)

		// when
		await store.send(.view(.backButtonTapped))

		// then
		await store.receive(.delegate(.dismissChooseAccounts))
	}

	func test_didSelectAccount_whenTappedOnSelectedAccount_thenDeselectThatAccount() async {
		// given
		var accountRow = ChooseAccounts.Row.State.placeholderOne
		accountRow.isSelected = true

		let initialState: ChooseAccounts.State = .init(
			request: .init(requestItem: .init(numberOfAddresses: 1), parentRequest: .placeholder),
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
		await store.send(.child(.account(id: accountRow.id, action: .view(.didSelect)))) {
			// then
			$0.accounts[id: accountRow.id]?.isSelected = false
			$0.canProceed = false
		}
	}

	func test_didSelectAccount_whenTappedOnDeselectedAccount_thenSelectThatAccount_ifMustSelectAtLeastOneAccount() async {
		// given
		var accountRowOne = ChooseAccounts.Row.State.placeholderOne
		accountRowOne.isSelected = false

		var accountRowTwo = ChooseAccounts.Row.State.placeholderTwo
		accountRowTwo.isSelected = false

		let initialState: ChooseAccounts.State = .init(
			request: .init(requestItem: .init(numberOfAddresses: .oneOrMore), parentRequest: .placeholder),
			canProceed: false,
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
			$0.canProceed = true
		}

		// when
		await store.send(.child(.account(id: accountRowTwo.id, action: .view(.didSelect)))) {
			// then
			$0.accounts[id: accountRowTwo.id]?.isSelected = true
		}
	}

	func test_didSelectAccount_whenTappedOnDeselectedAccount_thenSelectThatAccount_ifNotOverSelectedAccountLimit() async {
		// given
		var accountRow = ChooseAccounts.Row.State.placeholderOne
		accountRow.isSelected = false

		let initialState: ChooseAccounts.State = .init(
			request: .init(requestItem: .init(numberOfAddresses: .exactly(1)), parentRequest: .placeholder),
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
		await store.send(.child(.account(id: accountRow.id, action: .view(.didSelect)))) {
			// then
			$0.accounts[id: accountRow.id]?.isSelected = true
			$0.canProceed = true
		}
	}

	func test_didSelectAccount_whenTappedOnDeselectedAccount_thenDontSelectThatAccount_ifOverSelectedAccountLimit() async {
		// given
		var accountRowOne = ChooseAccounts.Row.State.placeholderOne
		accountRowOne.isSelected = true

		var accountRowTwo = ChooseAccounts.Row.State.placeholderTwo
		accountRowTwo.isSelected = false

		let initialState: ChooseAccounts.State = .init(
			request: .init(requestItem: .init(numberOfAddresses: .exactly(1)), parentRequest: .placeholder),
			canProceed: true,
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
