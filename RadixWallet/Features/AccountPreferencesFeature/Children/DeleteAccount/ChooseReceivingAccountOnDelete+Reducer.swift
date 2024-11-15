import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - ChooseReceivingAccountOnDelete
struct ChooseReceivingAccountOnDelete: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var chooseAccounts: ChooseAccounts.State
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
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case confirmSkipAlert(ConfirmSkipAlert)

			enum ConfirmSkipAlert: Hashable, Sendable {
				case cancelTapped
				case continueTapped
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
			TextState("Assets Will Be Lost")
		} actions: {
			ButtonState(role: .cancel, action: .cancelTapped) {
				TextState(L10n.Common.cancel)
			}
			ButtonState(role: .destructive, action: .continueTapped) {
				TextState(L10n.Common.continue)
			}
		} message: {
			TextState("If you do not transfer your assets out of this Account, they will be lost forever.")
		}
	}
}
