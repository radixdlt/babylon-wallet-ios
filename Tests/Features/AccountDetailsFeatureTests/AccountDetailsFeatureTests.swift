@testable import AccountDetailsFeature
import AccountListFeature
import FeatureTestingPrelude

@MainActor
final class AccountDetailsFeatureTests: TestCase {
	func test_dismissAccountDetails_whenTappedOnBackButton_thenCoordinateDismissal() async {
		// given
		let accountListRowState = AccountList.Row.State(account: .previewValue0)
		let initialState = AccountDetails.State(for: accountListRowState)
		let store = TestStore(
			initialState: initialState,
			reducer: AccountDetails()
		)

		// when
		await store.send(.internal(.view(.dismissAccountDetailsButtonTapped)))

		// then
		await store.receive(.delegate(.dismissAccountDetails))
	}

	func test_navigateToAccountPreferences_whenTappedOnPreferencesButton_thenCoordinateNavigationToPreferences() async {
		// given
		let account = OnNetwork.Account.previewValue0
		let accountListRowState = AccountList.Row.State(account: account)
		let initialState = AccountDetails.State(for: accountListRowState)
		let store = TestStore(
			initialState: initialState,
			reducer: AccountDetails()
		)

		// when
		await store.send(.internal(.view(.displayAccountPreferencesButtonTapped)))

		// then
		await store.receive(.delegate(.displayAccountPreferences(account.address)))
	}

	func test_copyAddress_whenTappedOnCopyAddress_thenCopyToPasteboard() async {
		// given
		let account = OnNetwork.Account.previewValue0
		let accountListRowState = AccountList.Row.State(account: account)
		let initialState = AccountDetails.State(for: accountListRowState)
		let store = TestStore(
			initialState: initialState,
			reducer: AccountDetails()
		)

		let expectation = expectation(description: "Address copied")
		store.dependencies.pasteboardClient.copyString = { copyString in
			// assert
			XCTAssertEqual(copyString, account.address.address)
			expectation.fulfill()
		}

		// when
		await store.send(.internal(.view(.copyAddressButtonTapped)))
		wait(for: [expectation], timeout: 0)
	}

	func test_refresh_whenInitiatedRefresh_thenCoordinateRefreshForAddress() async {
		// given
		let account = OnNetwork.Account.previewValue0
		let accountListRowState = AccountList.Row.State(account: account)
		let initialState = AccountDetails.State(for: accountListRowState)
		let store = TestStore(
			initialState: initialState,
			reducer: AccountDetails()
		)

		// when
		await store.send(.internal(.view(.pullToRefreshStarted)))

		// then
		await store.receive(.delegate(.refresh(account.address)))
	}

	// FIXME: @davdroman-rdx
//	func test_displayTransfer_whenTappedOnDisplayTransfer_thenCoordinateNavigationToTransfer() async {
//		// given
//		let account = OnNetwork.Account.testValue
//		let accountListRowState = AccountList.Row.State(account: account)
//		let initialState = AccountDetails.State(for: accountListRowState)
//		let store = TestStore(
//			initialState: initialState,
//			reducer: AccountDetails()
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
