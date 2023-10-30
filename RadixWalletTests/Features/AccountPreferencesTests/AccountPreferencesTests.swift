@testable import Radix_Wallet_Dev
import XCTest

@MainActor
final class AccountPreferencesTests: TestCase {
	func test_hideAccount_flow() async {
		var account = Profile.Network.Account.previewValue0

		let store = TestStore(
			initialState: AccountPreferences.State(account: account),
			reducer: AccountPreferences.init
		)

		await store.send(.view(.hideAccountTapped)) { state in
			state.destinations = .confirmHideAccount(.init(
				title: .init(L10n.AccountSettings.hideThisAccount),
				message: .init(L10n.AccountSettings.hideAccountConfirmation),
				buttons: [
					.default(.init(L10n.Common.continue), action: .send(.confirmTapped)),
					.cancel(.init(L10n.Common.cancel), action: .send(.cancelTapped)),
				]
			))
		}

		let updateAccount = ActorIsolated<Profile.Network.Account?>(nil)
		store.dependencies.entitiesVisibilityClient.hideAccount = { account in
			await updateAccount.setValue(account)
		}

		let scheduleCompletionHUD = ActorIsolated<OverlayWindowClient.Item.HUD?>(nil)
		store.dependencies.overlayWindowClient.scheduleHUD = { hud in
			Task {
				await scheduleCompletionHUD.setValue(hud)
			}
		}

		await store.send(.child(.destinations(.presented(.confirmHideAccount(.confirmTapped))))) { state in
			state.destinations = nil
		}

		let updatedAccount = await updateAccount.value
		XCTAssertEqual(account, updatedAccount)

		let scheduledCompletionHUD = await scheduleCompletionHUD.value
		XCTAssertEqual(scheduledCompletionHUD, .accountHidden)

		await store.receive(.delegate(.accountHidden))
	}
}
