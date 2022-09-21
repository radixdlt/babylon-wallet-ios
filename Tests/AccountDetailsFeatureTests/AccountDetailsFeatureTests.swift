@testable import AccountDetailsFeature
import AccountListFeature
import ComposableArchitecture
import Profile
import TestUtils

@MainActor
final class AccountDetailsFeatureTests: TestCase {
	func test_dismissAccountDetails_whenTappedOnBackButton_thenCoordinateDismissal() async {
		// given
		guard let account = Profile.placeholder.accounts.first else {
			XCTFail("No account present")
			return
		}
		let accountListRowState = AccountList.Row.State(account: account)
		let initialState = AccountDetails.State(for: accountListRowState)
		let store = TestStore(
			initialState: initialState,
			reducer: AccountDetails.reducer,
			environment: .unimplemented
		)

		// when
		_ = await store.send(.internal(.user(.dismissAccountDetails)))

		// then
		await store.receive(.coordinate(.dismissAccountDetails))
	}

	func test_navigateToAccountPreferences_whenTappedOnPreferencesButton_thenCoordinateNavigationToPreferences() async {
		// given
		guard let account = Profile.placeholder.accounts.first else {
			XCTFail("No account present")
			return
		}
		let accountListRowState = AccountList.Row.State(account: account)
		let initialState = AccountDetails.State(for: accountListRowState)
		let store = TestStore(
			initialState: initialState,
			reducer: AccountDetails.reducer,
			environment: .unimplemented
		)

		// when
		_ = await store.send(.internal(.user(.displayAccountPreferences)))

		// then
		await store.receive(.coordinate(.displayAccountPreferences))
	}

	func test_copyAddress_whenTappedOnCopyAddress_thenCoordiateCopiedAddress() async {
		// given
		guard let account = Profile.placeholder.accounts.first else {
			XCTFail("No account present")
			return
		}
		let accountListRowState = AccountList.Row.State(account: account)
		let initialState = AccountDetails.State(for: accountListRowState)
		let store = TestStore(
			initialState: initialState,
			reducer: AccountDetails.reducer,
			environment: .unimplemented
		)

		// when
		_ = await store.send(.internal(.user(.copyAddress)))

		// then
		await store.receive(.coordinate(.copyAddress(store.state.address)))
	}

	func test_refresh_whenInitiatedRefresh_thenCoordinateRefreshForAddress() async {
		// given
		guard let account = Profile.placeholder.accounts.first else {
			XCTFail("No account present")
			return
		}
		let accountListRowState = AccountList.Row.State(account: account)
		let initialState = AccountDetails.State(for: accountListRowState)
		let store = TestStore(
			initialState: initialState,
			reducer: AccountDetails.reducer,
			environment: .unimplemented
		)

		// when
		_ = await store.send(.internal(.user(.refresh)))

		// then
		await store.receive(.coordinate(.refresh(store.state.address)))
	}

	func test_displayTransfer_whenTappedOnDisplayTransfer_thenCoordinateNavigationToTransfer() async {
		// given
		guard let account = Profile.placeholder.accounts.first else {
			XCTFail("No account present")
			return
		}
		let accountListRowState = AccountList.Row.State(account: account)
		let initialState = AccountDetails.State(for: accountListRowState)
		let store = TestStore(
			initialState: initialState,
			reducer: AccountDetails.reducer,
			environment: .unimplemented
		)

		// when
		_ = await store.send(.internal(.user(.displayTransfer)))

		await store.receive(.coordinate(.displayTransfer))
	}
}
