@testable import Radix_Wallet_Dev
import Sargon
import XCTest

@MainActor
final class AccountPreferencesTests: TestCase {
	func test_hideAccount_flow() async {
		var account = Account.previewValue0

		let store = TestStore(
			initialState: AccountPreferences.State(account: account),
			reducer: AccountPreferences.init
		)

		await store.send(.view(.hideAccountTapped)) { state in
			state.destination = .hideAccount
		}

		let idOfUpdatedAccount = ActorIsolated<Account.ID?>(nil)
		store.dependencies.entitiesVisibilityClient.hideAccount = { account in
			await idOfUpdatedAccount.setValue(account)
		}

		let scheduleCompletionHUD = ActorIsolated<OverlayWindowClient.Item.HUD?>(nil)
		store.dependencies.overlayWindowClient.scheduleHUD = { hud in
			Task {
				await scheduleCompletionHUD.setValue(hud)
			}
		}

		await store.send(.destination(.presented(.hideAccount(.confirm)))) { state in
			state.destination = nil
		}

		let idOfUpdatedAccount_ = await idOfUpdatedAccount.value
		XCTAssertEqual(account.id, idOfUpdatedAccount_)

		let scheduledCompletionHUD = await scheduleCompletionHUD.value
		XCTAssertEqual(scheduledCompletionHUD, .accountHidden)

		await store.receive(.delegate(.accountHidden))
	}
}
