import FeaturePrelude

// MARK: - Completion
struct Completion: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let dappContext: DappContext

		init(
			dappContext: DappContext
		) {
			self.dappContext = dappContext
		}
	}

	enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case willDisappear
	}

	enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped, .willDisappear:
			return .send(.delegate(.dismiss))
		}
	}
}
