@testable import AccountListFeature
import FeaturePrelude
import Profile
import TestUtils

@MainActor
final class AccountListFeatureTests: TestCase {
	func test_copyAddress_whenTappedOnCopyAddress_thenCopyToPasteboard() async {
		// given
		let account = OnNetwork.Account.testValue
		let initialState = AccountList.State(nonEmptyOrderedSetOfAccounts: .init(rawValue: [account])!)
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
		wait(for: [expectation], timeout: 0)
	}
}
