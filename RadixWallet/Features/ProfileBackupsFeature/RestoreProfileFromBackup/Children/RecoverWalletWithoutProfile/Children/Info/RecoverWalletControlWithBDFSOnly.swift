// MARK: - RecoverWalletControlWithBDFSOnly

struct RecoverWalletControlWithBDFSOnly: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		init() {}
	}

	enum ViewAction: Sendable, Equatable {
		case continueTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case `continue`
	}

	init() {}

	func reduce(into _: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .continueTapped:
			.send(.delegate(.continue))
		}
	}
}
