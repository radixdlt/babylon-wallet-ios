@testable import AccountDetailsFeature
import FeatureTestingPrelude

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

	// FIXME: @davdroman-rdx after proper TCA tools are released
//	func test_navigateToAccountPreferences_whenTappedOnPreferencesButton_thenCoordinateNavigationToPreferences() async {
//		// given
//		let account = Profile.Network.Account.previewValue0
//		let store = TestStore(
//			initialState: AccountDetails.State(
//				for: AccountList.Row.State(account: account)
//			),
//			reducer: AccountDetails.init
//		)
//
//		// when
//		await store.send(.internal(.view(.preferencesButtonTapped))) {
//			// then
//			$0.destination = .preferences(.init(address: account.address))
//		}
//	}

	// FIXME: @davdroman-rdx after proper TCA tools are released
//	func test_displayTransfer_whenTappedOnDisplayTransfer_thenCoordinateNavigationToTransfer() async {
//		// given
//		let account = Profile.Network.Account.testValue
//		let accountListRowState = AccountList.Row.State(account: account)
//		let initialState = AccountDetails.State(for: accountListRowState)
//		let store = TestStore(
//			initialState: initialState,
//			reducer: AccountDetails.init
//		)
//
//		// when
//		await store.send(.internal(.view(.transferButtonTapped))) {
//			// then
//			$0.destination = .transfer(
//				.init(
//					from: account,
//					asset: .token(.xrd),
//					amount: nil,
//					to: nil
//				)
//			)
//		}
//	}
}
