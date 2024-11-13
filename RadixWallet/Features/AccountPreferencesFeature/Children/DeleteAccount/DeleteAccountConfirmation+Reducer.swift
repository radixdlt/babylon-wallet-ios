import ComposableArchitecture
import Sargon
import SwiftUI

struct DeleteAccountConfirmation: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let account: Account

		@PresentationState
		var destination: Destination.State? = nil

		init(account: Account) {
			self.account = account
		}
	}

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case continueButtonTapped
		case cancelButtonTapped
	}

	@CasePathable
	enum DelegateAction: Sendable, Equatable {
		case cancel
	}

	// MARK: - Destination
	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable, Sendable {
			case chooseReceivingAccount(ChooseReceivingAccountOnDelete.State)
		}

		@CasePathable
		enum Action: Equatable, Sendable {
			case chooseReceivingAccount(ChooseReceivingAccountOnDelete.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.chooseReceivingAccount, action: \.chooseReceivingAccount) {
				ChooseReceivingAccountOnDelete()
			}
		}
	}

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.errorQueue) var errorQueue

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: \.destination) {
				Destination()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .continueButtonTapped:
			state.destination = .chooseReceivingAccount(.init(
				chooseAccounts: .init(
					context: .accountDeletion,
					filteredAccounts: [state.account.accountAddress],
					canCreateNewAccount: false
				)
			))

			return .none

		case .cancelButtonTapped:
			return .send(.delegate(.cancel))
		}
	}
}
