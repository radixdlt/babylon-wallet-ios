import TestUtils

import Collections
import ComposableArchitecture
import NonEmpty
import ProfileClient
import SharedModels

@testable import GrantDappWalletAccessFeature

// MARK: - IncomingConnectionRequestFromDappReviewFeatureTests
@MainActor
final class IncomingConnectionRequestFromDappReviewFeatureTests: TestCase {
	func test_dismissIncomingConnectionRequest_whenTappedOnCloseButton_thenCoortinateDismissal() async {
		// given
		let requestItem: P2P.OneTimeAccountAddressesRequestToHandle = .init(
			requestItem: .init(numberOfAddresses: 1),
			parentRequest: .placeholder
		)

		let initialState: DappConnectionRequest.State = .init(
			request: .init(
				requestItem: requestItem.requestItem,
				parentRequest: requestItem.parentRequest
			)
		)

		let store = TestStore(
			initialState: initialState,
			reducer: DappConnectionRequest()
		)

		// when
		_ = await store.send(.view(.dismissButtonTapped))

		// then
		_ = await store.receive(.delegate(.dismiss(requestItem)))
	}

	func test_proceedWithConnectionRequest_whenTappedOnContinueButton_thenDisplayChooseAccounts() async {
		// given
		let requestItem: P2P.OneTimeAccountAddressesRequestToHandle = .init(
			requestItem: .init(numberOfAddresses: 1),
			parentRequest: .placeholder
		)

		let initialState: DappConnectionRequest.State = .init(
			request: .init(
				requestItem: requestItem.requestItem,
				parentRequest: requestItem.parentRequest
			)
		)
		let store = TestStore(
			initialState: initialState,
			reducer: DappConnectionRequest()
		)
		let accounts: NonEmpty<OrderedSet<OnNetwork.Account>> = .init(rawValue: .init([.mocked0, .mocked1]))!
		store.dependencies.profileClient.getAccounts = { @Sendable in accounts }

		// when
		_ = await store.send(.view(.continueButtonTapped))

		// then

		_ = await store.receive(.internal(.system(.loadAccountsResult(.success(accounts))))) {
			$0.chooseAccounts = .init(
				request: requestItem,
				accounts: .init(uniqueElements: accounts.rawValue.elements.map {
					ChooseAccounts.Row.State(account: $0)
				})
			)
		}
	}

	func test_dismissChooseAccounts_whenCoordinatedToDismissChooseAccounts_thenDismissChooseAccounts() async {
		// given
		let requestItem: P2P.OneTimeAccountAddressesRequestToHandle = .init(
			requestItem: .init(numberOfAddresses: 1),
			parentRequest: .placeholder
		)

		let initialState: DappConnectionRequest.State = .init(
			request: .init(
				requestItem: requestItem.requestItem,
				parentRequest: requestItem.parentRequest
			),
			chooseAccounts: .placeholder
		)
		let store = TestStore(
			initialState: initialState,
			reducer: DappConnectionRequest()
		)

		// when
		_ = await store.send(.child(.chooseAccounts(.delegate(.dismissChooseAccounts)))) {
			// then
			$0.chooseAccounts = nil
		}
	}
}
