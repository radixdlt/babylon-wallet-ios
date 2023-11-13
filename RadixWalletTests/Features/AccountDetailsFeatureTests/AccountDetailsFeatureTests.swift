@testable import Radix_Wallet_Dev
import XCTest

// MARK: - AccountDetailsFeatureTests
@MainActor
final class AccountDetailsFeatureTests: TestCase {
	func test_dismissAccountDetails_whenTappedOnBackButton_thenCoordinateDismissal() async {
		// given
		let store = TestStore(
			initialState: AccountDetails.State(
				accountWithInfo: .previewValue0
			),
			reducer: AccountDetails.init
		)

		// when
		await store.send(.view(.backButtonTapped))

		// then
		await store.receive(.delegate(.dismiss))
	}

	func test_accountHidden_thenCoordinateDismissal() async {
		let store = TestStore(
			initialState: AccountDetails.State(
				accountWithInfo: .previewValue0
			),
			reducer: AccountDetails.init
		)

		await store.send(.view(.preferencesButtonTapped)) { state in
			state.destination = .preferences(.init(account: state.account))
		}

		await store.send(.child(.destination(.presented(.preferences(.delegate(.accountHidden))))))

		await store.receive(.delegate(.dismiss))
	}
}

extension AccountWithInfo {
	static let previewValue0 = Self(account: .previewValue0)
}
