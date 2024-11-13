import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - ChooseReceivingAccount
struct ChooseReceivingAccountOnDelete: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var chooseAccounts: ChooseAccounts.State

		@PresentationState
		var destination: Destination.State? = nil

		init(chooseAccounts: ChooseAccounts.State) {
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
			case scanAccountAddress(ScanQRCoordinator.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case scanAccountAddress(ScanQRCoordinator.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.scanAccountAddress, action: \.scanAccountAddress) {
				ScanQRCoordinator()
			}
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
			.none

		case .skipButtonTapped:
			.none
		}
	}
}
