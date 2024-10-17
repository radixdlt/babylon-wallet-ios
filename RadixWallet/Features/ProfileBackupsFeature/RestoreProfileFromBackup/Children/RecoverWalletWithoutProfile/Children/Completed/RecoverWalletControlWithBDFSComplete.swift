// MARK: - RecoverWalletControlWithBDFSComplete

struct RecoverWalletControlWithBDFSComplete: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		init() {}
	}

	enum ViewAction: Sendable, Equatable {
		case continueButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case profileCreatedFromImportedBDFS
	}

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .continueButtonTapped:
			.send(.delegate(.profileCreatedFromImportedBDFS))
		}
	}
}
