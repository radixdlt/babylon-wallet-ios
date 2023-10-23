@testable import Radix_Wallet_Dev
import XCTest

@MainActor
final class AccountDetailsFeatureTests: TestCase {
	func test_dismissAccountDetails_whenTappedOnBackButton_thenCoordinateDismissal() async {
		// given
		let store = TestStore(
			initialState: AccountDetails.State(
				for: .previewValue0
			),
			reducer: AccountDetails.init
		)

		// when
		await store.send(.view(.backButtonTapped))

		// then
		await store.receive(.delegate(.dismiss))
	}

	func test_dismissAccountDetails_whenTappedOnBackButton_thenCoordinateDismissal() async {
		// given
		let store = TestStore(
			initialState: AccountDetails.State(
				for: .previewValue0
			),
			reducer: AccountDetails.init
		)

		// when
		await store.send(.view(.backButtonTapped))

		// then
		await store.receive(.delegate(.dismiss))
	}
}
