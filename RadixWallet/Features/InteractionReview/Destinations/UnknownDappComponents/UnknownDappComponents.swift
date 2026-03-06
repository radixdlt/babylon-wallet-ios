import ComposableArchitecture

extension InteractionReview {
	@Reducer
	struct UnknownDappComponents: FeatureReducer {
		@ObservableState
		struct State: Hashable {
			let title: String
			let rowHeading: String
			let addresses: [LedgerIdentifiable.Address]
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction {
			case closeButtonTapped
		}

		@Dependency(\.dismiss) var dismiss

		var body: some ReducerOf<Self> {
			Reduce(core)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .closeButtonTapped:
				.run { _ in
					await dismiss()
				}
			}
		}
	}
}
