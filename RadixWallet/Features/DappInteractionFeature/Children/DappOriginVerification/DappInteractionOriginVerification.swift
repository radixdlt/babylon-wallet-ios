struct DappInteractionOriginVerification: FeatureReducer {
	@ObservableState
	struct State: Hashable, Equatable {
		let dAppMetadata: DappMetadata

		init(dAppMetadata: DappMetadata) {
			self.dAppMetadata = dAppMetadata
		}
	}

	enum ViewAction: Equatable {
		case continueTapped
		case cancel
	}

	enum DelegateAction: Equatable {
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
