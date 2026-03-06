// MARK: - RecoverWalletControlWithBDFSComplete

struct RecoverWalletControlWithBDFSComplete: FeatureReducer {
	struct State: Hashable {
		init() {}
	}

	enum ViewAction: Equatable {
		case continueButtonTapped
	}

	enum DelegateAction: Equatable {
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
