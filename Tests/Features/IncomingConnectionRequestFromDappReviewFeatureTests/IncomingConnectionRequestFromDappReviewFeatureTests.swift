import Collections
import ComposableArchitecture
@testable import IncomingConnectionRequestFromDappReviewFeature
import NonEmpty
import ProfileClient
import TestUtils

import BrowserExtensionsConnectivityClient

extension IncomingMessageFromBrowser {
	static var placeholderAccountReq: Self {
		try! .init(
			requestMethodWalletRequest: .placeholderGetAccountAddressRequest,
			browserExtensionConnection: .placeholder
		)
	}
}

// MARK: - IncomingConnectionRequestFromDappReviewFeatureTests
@MainActor
final class IncomingConnectionRequestFromDappReviewFeatureTests: TestCase {
	func test_dismissIncomingConnectionRequest_whenTappedOnCloseButton_thenCoortinateDismissal() async {
		// given
		let initialState: IncomingConnectionRequestFromDappReview.State = .init(
			incomingMessageFromBrowser: .placeholderAccountReq,
			incomingConnectionRequestFromDapp: .placeholder
		)
		let store = TestStore(
			initialState: initialState,
			reducer: IncomingConnectionRequestFromDappReview()
		)

		// when
		_ = await store.send(.view(.dismissButtonTapped))

		// then
		_ = await store.receive(.delegate(.dismiss))
	}

	func test_proceedWithConnectionRequest_whenTappedOnContinueButton_thenDisplayChooseAccounts() async {
		// given
		let request: IncomingConnectionRequestFromDapp = .placeholder
		let initialState: IncomingConnectionRequestFromDappReview.State = .init(
			incomingMessageFromBrowser: .placeholderAccountReq,
			incomingConnectionRequestFromDapp: request
		)
		let store = TestStore(
			initialState: initialState,
			reducer: IncomingConnectionRequestFromDappReview()
		)
		let accounts: NonEmpty<OrderedSet<OnNetwork.Account>> = .init(rawValue: .init([.mocked0, .mocked1]))!
		store.dependencies.profileClient.getAccounts = { @Sendable in accounts }

		// when
		_ = await store.send(.view(.continueButtonTapped))

		// then

		_ = await store.receive(.internal(.system(.loadAccountsResult(.success(accounts))))) {
			$0.chooseAccounts = .init(
				incomingConnectionRequestFromDapp: request,
				accounts: .init(uniqueElements: accounts.rawValue.elements.map {
					ChooseAccounts.Row.State(account: $0)
				})
			)
		}
	}

	func test_dismissChooseAccounts_whenCoordinatedToDismissChooseAccounts_thenDismissChooseAccounts() async {
		// given
		let request: IncomingConnectionRequestFromDapp = .placeholder
		let initialState: IncomingConnectionRequestFromDappReview.State = .init(
			incomingMessageFromBrowser: .placeholderAccountReq,
			incomingConnectionRequestFromDapp: request,
			chooseAccounts: .placeholder
		)
		let store = TestStore(
			initialState: initialState,
			reducer: IncomingConnectionRequestFromDappReview()
		)

		// when
		_ = await store.send(.child(.chooseAccounts(.delegate(.dismissChooseAccounts)))) {
			// then
			$0.chooseAccounts = nil
		}
	}
}
