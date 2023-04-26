@testable import AccountListFeature
import FeatureTestingPrelude

@MainActor
final class AccountListFeatureTests: TestCase {
	func test_copyAddress_whenTappedOnCopyAddress_thenCopyToPasteboard() async {
		// given
		let account = Profile.Network.Account.previewValue0
		let initialState = AccountList.State(accounts: .init(rawValue: [account])!)
		let store = TestStore(initialState: initialState,
		                      reducer: AccountList())
		let expectation = expectation(description: "Address copied")
		store.dependencies.pasteboardClient.copyString = { copyString in
			// assert
			XCTAssertEqual(copyString, account.address.address)
			expectation.fulfill()
		}

		// when
		await store.send(.child(.account(id: initialState.accounts.first!.id, action: .view(.copyAddressButtonTapped))))
		await store.receive(.child(.account(id: initialState.accounts.first!.id, action: .delegate(.copyAddressButtonTapped(account)))))
		wait(for: [expectation], timeout: 0)
	}
}
