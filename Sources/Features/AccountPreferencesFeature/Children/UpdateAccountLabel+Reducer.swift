import AccountsClient
import FeaturePrelude
import OverlayWindowClient

// MARK: - UpdateAccountLabel
public struct UpdateAccountLabel: FeatureReducer, Sendable {
	public struct State: Hashable, Sendable {
		var account: Profile.Network.Account
		var accountLabel: String
		var sanitizedName: NonEmptyString?

		init(account: Profile.Network.Account) {
			self.account = account
			self.accountLabel = account.displayName.rawValue
			self.sanitizedName = account.displayName
		}
	}

	public enum ViewAction: Equatable, Sendable {
		case accountLabelChanged(String)
		case updateTapped(NonEmptyString)
	}

	public enum DelegateAction: Equatable, Sendable {
		case accountLabelUpdated
	}

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .accountLabelChanged(label):
			state.accountLabel = label
			state.sanitizedName = NonEmpty(rawValue: label.trimmingWhitespace())
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
