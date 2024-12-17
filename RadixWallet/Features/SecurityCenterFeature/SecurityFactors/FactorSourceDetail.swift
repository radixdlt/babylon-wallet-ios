// MARK: - DeviceFactorSourceDetail

struct FactorSourceDetail: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let integrity: FactorSourceIntegrity
	}

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
