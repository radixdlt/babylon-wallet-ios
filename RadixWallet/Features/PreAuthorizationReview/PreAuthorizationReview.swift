// MARK: - PreAuthorizationReview
@Reducer
struct PreAuthorizationReview: Sendable, FeatureReducer {
	typealias Common = InteractionReviewCommon

	@ObservableState
	struct State: Sendable, Hashable {
		var dappName: String? = "Collabo.Fi"
		var displayMode: Common.DisplayMode = .detailed
		init() {}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case appeared
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			.none
		}
	}
}
