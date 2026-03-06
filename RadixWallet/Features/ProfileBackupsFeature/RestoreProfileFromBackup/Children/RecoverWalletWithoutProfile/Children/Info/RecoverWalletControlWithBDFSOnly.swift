// MARK: - RecoverWalletControlWithBDFSOnly

struct RecoverWalletControlWithBDFSOnly: FeatureReducer {
	struct State: Hashable {
		init() {}
	}

	enum ViewAction: Equatable {
		case continueTapped
	}

	enum DelegateAction: Equatable {
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
