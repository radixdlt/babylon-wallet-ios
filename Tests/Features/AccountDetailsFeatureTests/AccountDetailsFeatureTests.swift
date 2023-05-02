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
			reducer: AccountDetails()
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
//			reducer: AccountDetails()
//		)
//
//		// when
//		await store.send(.internal(.view(.preferencesButtonTapped))) {
//			// then
//			$0.destination = .preferences(.init(address: account.address))
//		}
//	}

	func test_copyAddress_whenTappedOnCopyAddress_thenCopyToPasteboard() async {
		// given
		let account = Profile.Network.Account.previewValue0
		let initialState = AccountDetails.State(for: account)
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
		await store.send(.view(.copyAddressButtonTapped))
		wait(for: [expectation], timeout: 0)
	}

	func test_refresh_whenInitiatedRefresh_thenCoordinateRefreshForAddress() async {
		// given
		let account = Profile.Network.Account.previewValue0
		let initialState = AccountDetails.State(for: account)
		let store = TestStore(
			initialState: initialState,
			reducer: AccountDetails()
		)

		let didFetchAccountPortfolio: ActorIsolated<(address: String, forceRefresh: Bool)?> = ActorIsolated(nil)
		store.dependencies.accountPortfoliosClient.fetchAccountPortfolio = { address, forceRefresh in
			await didFetchAccountPortfolio.setValue((address.address, forceRefresh))
			return AccountPortfolio(owner: account.address, fungibleResources: .init(), nonFungibleResources: [])
		}

		// when
		await store.send(.view(.pullToRefreshStarted))

		await didFetchAccountPortfolio.withValue { value in
			XCTAssertEqual(value?.address, account.address.address)
			XCTAssertEqual(value?.forceRefresh, true)
		}
	}

	// FIXME: @davdroman-rdx after proper TCA tools are released
//	func test_displayTransfer_whenTappedOnDisplayTransfer_thenCoordinateNavigationToTransfer() async {
//		// given
//		let account = Profile.Network.Account.testValue
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
