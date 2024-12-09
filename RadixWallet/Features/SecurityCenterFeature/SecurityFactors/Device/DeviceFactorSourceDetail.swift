// MARK: - DeviceFactorSourceDetail

struct DeviceFactorSourceDetail: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {}

	enum ViewAction: Sendable, Equatable {
		case appeared
	}

	func reduce(into _: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			.none
		}
	}
}
