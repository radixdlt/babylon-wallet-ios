import AccountsClient
import FeaturePrelude
import OverlayWindowClient

// MARK: - UpdateAccountLabel
public struct UpdateAccountLabel: FeatureReducer {
	public struct State: Hashable, Sendable {
		var account: Profile.Network.Account
		var accountLabel: String

		init(account: Profile.Network.Account) {
			self.account = account
			self.accountLabel = account.displayName.rawValue
		}
	}

	public enum ViewAction: Equatable {
		case accountLabelChanged(String)
		case updateTapped(NonEmpty<String>)
	}

	public enum DelegateAction: Equatable {
		case accountLabelUpdated
	}

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .accountLabelChanged(label):
			state.accountLabel = label
			return .none
		case let .updateTapped(newLabel):
			state.account.displayName = newLabel
			return .run { [account = state.account] send in
				do {
					try await accountsClient.updateAccount(account)
					overlayWindowClient.scheduleHUD(.updated)
					await send(.delegate(.accountLabelUpdated))
				} catch {
					errorQueue.schedule(error)
				}
			}
		}
	}
}
