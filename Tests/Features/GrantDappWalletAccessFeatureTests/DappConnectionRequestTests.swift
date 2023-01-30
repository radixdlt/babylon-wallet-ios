import FeatureTestingPrelude
@testable import GrantDappWalletAccessFeature

// MARK: - IncomingConnectionRequestFromDappReviewFeatureTests
@MainActor
final class IncomingConnectionRequestFromDappReviewFeatureTests: TestCase {
	func test_dismissIncomingConnectionRequest_whenTappedOnCloseButton_thenCoortinateDismissal() async {
		// given
		let requestItem: P2P.OneTimeAccountsRequestToHandle = .init(
			requestItem: .init(numberOfAccounts: .exactly(1), requiresProofOfOwnership: false),
			parentRequest: .previewValue
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
		await store.send(.view(.dismissButtonTapped))

		// then
		await store.receive(.delegate(.rejected(requestItem)))
	}

	func test_proceedWithConnectionRequest_whenTappedOnContinueButton_thenNotifiesDelegate() async {
		// given
		let requestItem: P2P.OneTimeAccountsRequestToHandle = .init(
			requestItem: .init(numberOfAccounts: .exactly(1), requiresProofOfOwnership: false),
			parentRequest: .previewValue
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
		let accounts: NonEmpty<OrderedSet<OnNetwork.Account>> = .init(rawValue: .init([.previewValue0, .previewValue1]))!
		store.dependencies.profileClient.getAccounts = { @Sendable in accounts }

		// when
		await store.send(.view(.continueButtonTapped))

		// then
		await store.receive(.delegate(.allowed(requestItem)))
	}
}
