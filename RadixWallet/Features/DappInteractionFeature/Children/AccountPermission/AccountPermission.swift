import ComposableArchitecture
import SwiftUI

// MARK: - AccountPermission
struct AccountPermission: FeatureReducer {
	struct State: Hashable {
		let dappMetadata: DappMetadata
		let numberOfAccounts: DappInteractionNumberOfAccounts

		init(
			dappMetadata: DappMetadata,
			numberOfAccounts: DappInteractionNumberOfAccounts
		) {
			self.dappMetadata = dappMetadata
			self.numberOfAccounts = numberOfAccounts
		}
	}

	enum ViewAction: Equatable {
		case appeared
		case continueButtonTapped
	}

	enum DelegateAction: Equatable {
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
