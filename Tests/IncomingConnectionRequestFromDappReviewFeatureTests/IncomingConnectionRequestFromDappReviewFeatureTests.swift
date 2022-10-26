import ComposableArchitecture
@testable import IncomingConnectionRequestFromDappReviewFeature
import ProfileClient
import TestUtils

@MainActor
final class IncomingConnectionRequestFromDappReviewFeatureTests: TestCase {
	func test_dismissIncomingConnectionRequest_whenTappedOnCloseButton_thenCoortinateDismissal() async {
		// given
		let initialState: IncomingConnectionRequestFromDappReview.State = .init(
			incomingConnectionRequestFromDapp: .placeholder
		)
		let store = TestStore(
			initialState: initialState,
			reducer: IncomingConnectionRequestFromDappReview()
		)

		// when
		_ = await store.send(.internal(.user(.dismissIncomingConnectionRequest)))

		// then
		_ = await store.receive(.coordinate(.dismissIncomingConnectionRequest))
	}

	func test_proceedWithConnectionRequest_whenTappedOnContinueButton_thenDisplayChooseAccounts() async {
		// given
		let request: IncomingConnectionRequestFromDapp = .placeholder
		let initialState: IncomingConnectionRequestFromDappReview.State = .init(
			incomingConnectionRequestFromDapp: request
		)
		let store = TestStore(
			initialState: initialState,
			reducer: IncomingConnectionRequestFromDappReview()
		)
		let accounts = try! store.dependencies.profileClient.getAccounts()

		// when
		_ = await store.send(.internal(.user(.proceedWithConnectionRequest)))

		// then
		_ = await store.receive(.coordinate(.proceedWithConnectionRequest)) {
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
			incomingConnectionRequestFromDapp: request,
			chooseAccounts: .placeholder
		)
		let store = TestStore(
			initialState: initialState,
			reducer: IncomingConnectionRequestFromDappReview()
		)

		// when
		_ = await store.send(.chooseAccounts(.coordinate(.dismissChooseAccounts))) {
			// then
			$0.chooseAccounts = nil
		}
	}
}
