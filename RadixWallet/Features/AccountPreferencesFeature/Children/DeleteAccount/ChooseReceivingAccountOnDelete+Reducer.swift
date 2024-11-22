import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - ChooseReceivingAccountOnDelete
struct ChooseReceivingAccountOnDelete: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var chooseAccounts: ChooseAccounts.State
		var hasAccountsWithEnoughXRD: Bool
		var footerControlState: ControlState = .enabled

		@PresentationState
		var destination: Destination.State? = nil
	}

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case continueButtonTapped([ChooseAccountsRow.State])
		case skipButtonTapped
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case chooseAccounts(ChooseAccounts.Action)
	}

	@CasePathable
	enum DelegateAction: Sendable, Equatable {
		case finished(AccountAddress?)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case confirmSkipAlert(AlertState<Action.ConfirmSkipAlert>)
			case tooManyAssetsAlert(AlertState<Action.TooManyAssetsAlert>)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case confirmSkipAlert(ConfirmSkipAlert)
			case tooManyAssetsAlert(TooManyAssetsAlert)

			enum ConfirmSkipAlert: Hashable, Sendable {
				case cancelTapped
				case continueTapped
			}

			enum TooManyAssetsAlert: Hashable, Sendable {
				case okTapped
			}
		}

		var body: some ReducerOf<Self> {
			EmptyReducer()
		}
	}

	init() {}

	var body: some ReducerOf<Self> {
		Scope(state: \.chooseAccounts, action: \.child.chooseAccounts) {
			ChooseAccounts()
		}

		Reduce(core)
			.ifLet(\.$destination, action: \.destination) {
				Destination()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .continueButtonTapped(selectedAccounts):
			guard let recipientAccount = selectedAccounts.first else {
				return .none
			}

			return .send(.delegate(.finished(recipientAccount.account.address)))

		case .skipButtonTapped:
			state.destination = .confirmSkipAlert(.confirmSkip)
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .confirmSkipAlert(.continueTapped):
			state.footerControlState = .loading(.local)
			return .send(.delegate(.finished(nil)))
		default:
			return .none
		}
	}
}

extension AlertState<ChooseReceivingAccountOnDelete.Destination.Action.ConfirmSkipAlert> {
	static var confirmSkip: AlertState {
		AlertState {
			TextState(L10n.AccountSettings.AssetsWillBeLostWarning.title)
		} actions: {
			ButtonState(role: .cancel, action: .cancelTapped) {
				TextState(L10n.Common.cancel)
			}
			ButtonState(role: .destructive, action: .continueTapped) {
				TextState(L10n.Common.continue)
			}
		} message: {
			TextState(L10n.AccountSettings.AssetsWillBeLostWarning.message)
		}
	}
}

extension AlertState<ChooseReceivingAccountOnDelete.Destination.Action.TooManyAssetsAlert> {
	static var tooManyAssets: AlertState {
		AlertState {
			TextState(L10n.AccountSettings.CannotDeleteAccountWarning.title)
		} actions: {
			ButtonState(role: .cancel, action: .okTapped) {
				TextState(L10n.Common.ok)
			}
		} message: {
			TextState(L10n.AccountSettings.CannotDeleteAccountWarning.message)
		}
	}
}
