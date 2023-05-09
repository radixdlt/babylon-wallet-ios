import FeaturePrelude

// MARK: - AccountPermission
struct AccountPermission: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let dappContext: DappContext
		let numberOfAccounts: DappInteraction.NumberOfAccounts

		init(
			dappContext: DappContext,
			numberOfAccounts: DappInteraction.NumberOfAccounts
		) {
			self.dappContext = dappContext
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

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .continueButtonTapped:
			return .send(.delegate(.continueButtonTapped))
		}
	}
}
