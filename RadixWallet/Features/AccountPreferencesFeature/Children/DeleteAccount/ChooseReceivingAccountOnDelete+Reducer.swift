import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - ChooseReceivingAccountOnDelete
struct ChooseReceivingAccountOnDelete: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let accountToDelete: Account
		var chooseAccounts: ChooseAccounts.State

		@PresentationState
		var destination: Destination.State? = nil

		init(accountToDelete: Account, chooseAccounts: ChooseAccounts.State) {
			self.accountToDelete = accountToDelete
			self.chooseAccounts = chooseAccounts
		}
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

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case confirmSkip(AlertState<Action.ConfirmSkipAlert>)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case confirmSkip(ConfirmSkipAlert)

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
			return .none

		case .skipButtonTapped:
			state.destination = .confirmSkip(.confirmSkip)
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .confirmSkip(.continueTapped):
			// TODO: review transaction
			.none

		default:
			.none
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
