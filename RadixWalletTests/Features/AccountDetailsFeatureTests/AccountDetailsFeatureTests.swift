@testable import Radix_Wallet_Dev
import Sargon
import XCTest

// MARK: - AccountDetailsFeatureTests
@MainActor
final class AccountDetailsFeatureTests: TestCase {
	func test_backButtonTapped_doesNotStartReducerDrivenDismissal() async {
		// given
		let store = TestStore(
			initialState: AccountDetails.State(
				accountWithInfo: .previewValue0,
				showFiatWorth: false
			),
			reducer: AccountDetails.init
		)

		// when
		await store.send(.view(.backButtonTapped))
	}

	func test_accountHidden_thenCoordinateDismissal() async {
		let store = TestStore(
			initialState: AccountDetails.State(
				accountWithInfo: .previewValue0,
				showFiatWorth: false
			),
			reducer: AccountDetails.init
		)

		await store.send(.view(.preferencesButtonTapped)) { state in
			state.destination = .preferences(.init(account: state.account))
		}

		await store.send(.destination(.presented(.preferences(.delegate(.accountHidden)))))

		await store.receive(.delegate(.dismiss))
	}
}

extension AccountWithInfo {
	static let previewValue0 = Self(account: .previewValue0)
}

// MARK: - HomeDestinationQueueTests
@MainActor
final class HomeDestinationQueueTests: XCTestCase {
	func test_dismissDestination_thenPresentQueuedDestinationInSeparateStep() async {
		let destination = Home.Destination.State.accountDetails(.init(
			accountWithInfo: .previewValue0,
			showFiatWorth: false
		))
		var initialState = Home.State()
		initialState.addDestination(destination)
		initialState.addDestination(destination)
		let store = TestStore(initialState: initialState, reducer: Home.init)

		await store.send(.destination(.dismiss)) {
			$0.destination = nil
		}
		await store.receive(.internal(.showNextDestination)) {
			$0.destination = destination
		}
	}
}
