import ComposableArchitecture
import SwiftUI

// MARK: - UpdateAccountLabel
struct UpdateAccountLabel: FeatureReducer, Sendable {
	struct State: Hashable, Sendable {
		var account: Account
		var accountLabel: String
		var sanitizedName: NonEmptyString?
		var textFieldFocused: Bool = true

		init(account: Account) {
			self.account = account
			self.accountLabel = account.displayName.rawValue
			self.sanitizedName = account.displayName.asNonEmpty
		}
	}

	enum ViewAction: Equatable, Sendable {
		case accountLabelChanged(String)
		case updateTapped(NonEmptyString)
		case focusChanged(Bool)
	}

	enum DelegateAction: Equatable, Sendable {
		case accountLabelUpdated
	}

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .accountLabelChanged(label):
			state.accountLabel = label
			state.sanitizedName = NonEmpty(rawValue: label.trimmingWhitespace())
			return .none

		case let .updateTapped(newLabel):
			state.account.displayName = DisplayName(nonEmpty: newLabel)

			return .run { [account = state.account] send in
				do {
					try await accountsClient.updateAccount(account)
					overlayWindowClient.scheduleHUD(.updatedAccount)
					await send(.delegate(.accountLabelUpdated))
				} catch {
					errorQueue.schedule(error)
				}
			}

		case let .focusChanged(value):
			state.textFieldFocused = value
			return .none
		}
	}
}
