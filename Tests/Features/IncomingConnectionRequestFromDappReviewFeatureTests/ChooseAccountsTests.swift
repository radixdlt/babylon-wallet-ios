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
			initialState: ChooseAccounts.State(incomingConnectionRequestFromDapp: .placeholder, accounts: [singleAccount]),
			reducer: ChooseAccounts()
		)

		// when
		_ = await store.send(.internal(.user(.finishedChoosingAccounts)))

		// then
		let expectedAccounts = NonEmpty(rawValue: OrderedSet(uncheckedUniqueElements: [singleAccount.account]))!
		_ = await store.receive(.coordinate(.finishedChoosingAccounts(expectedAccounts)))
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
		var accountRow = ChooseAccounts.Row.State.placeholderOne
		accountRow.isSelected = true

		let connectionRequest: IncomingConnectionRequestFromDapp = .init(
			componentAddress: "deadbeef",
			name: "Radaswap",
			permissions: [],
			numberOfNeededAccounts: .exactly(1)
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

	func test_didSelectAccount_whenTappedOnDeselectedAccount_thenSelectThatAccount_ifMustSelectAtLeastOneAccount() async {
		// given
		var accountRowOne = ChooseAccounts.Row.State.placeholderOne
		accountRowOne.isSelected = false

		var accountRowTwo = ChooseAccounts.Row.State.placeholderTwo
		accountRowTwo.isSelected = false

		let connectionRequest: IncomingConnectionRequestFromDapp = .init(
			componentAddress: "deadbeef",
			name: "Radaswap",
			permissions: [],
			numberOfNeededAccounts: .atLeastOne
		)

		let initialState: ChooseAccounts.State = .init(
			incomingConnectionRequestFromDapp: connectionRequest,
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
		_ = await store.send(.account(id: accountRowOne.id, action: .internal(.user(.didSelect)))) {
			// then
			$0.accounts[id: accountRowOne.id]?.isSelected = true
			$0.canProceed = true
		}

		// when
		_ = await store.send(.account(id: accountRowTwo.id, action: .internal(.user(.didSelect)))) {
			// then
			$0.accounts[id: accountRowTwo.id]?.isSelected = true
		}
	}

	func test_didSelectAccount_whenTappedOnDeselectedAccount_thenSelectThatAccount_ifNotOverSelectedAccountLimit() async {
		// given
		var accountRow = ChooseAccounts.Row.State.placeholderOne
		accountRow.isSelected = false

		let connectionRequest: IncomingConnectionRequestFromDapp = .init(
			componentAddress: "deadbeef",
			name: "Radaswap",
			permissions: [],
			numberOfNeededAccounts: .exactly(1)
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
		var accountRowOne = ChooseAccounts.Row.State.placeholderOne
		accountRowOne.isSelected = true

		var accountRowTwo = ChooseAccounts.Row.State.placeholderTwo
		accountRowTwo.isSelected = false

		let connectionRequest: IncomingConnectionRequestFromDapp = .init(
			componentAddress: "deadbeef",
			name: "Radaswap",
			permissions: [],
			numberOfNeededAccounts: .exactly(1)
		)

		let initialState: ChooseAccounts.State = .init(
			incomingConnectionRequestFromDapp: connectionRequest,
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
		_ = await store.send(.account(id: accountRowTwo.id, action: .internal(.user(.didSelect))))

		// then
		// no state change should occur
	}
}
