struct DappInteractionOriginVerification: FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable, Equatable {
		let dAppMetadata: DappMetadata

		init(dAppMetadata: DappMetadata) {
			self.dAppMetadata = dAppMetadata
		}
	}

	enum ViewAction: Sendable, Equatable {
		case continueTapped
		case cancel
	}

	enum DelegateAction: Sendable, Equatable {
		case continueFlow(DappMetadata)
		case cancel
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .continueTapped:
			.send(.delegate(.continueFlow(state.dAppMetadata)))
		case .cancel:
			.send(.delegate(.cancel))
		}
	}
}
