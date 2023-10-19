import ComposableArchitecture
import SwiftUI

// MARK: - AccountPermission
struct AccountPermission: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let dappMetadata: DappMetadata
		let numberOfAccounts: DappInteraction.NumberOfAccounts

		init(
			dappMetadata: DappMetadata,
			numberOfAccounts: DappInteraction.NumberOfAccounts
		) {
			self.dappMetadata = dappMetadata
			self.numberOfAccounts = numberOfAccounts
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case continueButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case continueButtonTapped
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			.none
		case .continueButtonTapped:
			.send(.delegate(.continueButtonTapped))
		}
	}
}
