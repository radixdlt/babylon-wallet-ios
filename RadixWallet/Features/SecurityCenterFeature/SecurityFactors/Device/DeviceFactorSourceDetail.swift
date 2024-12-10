// MARK: - DeviceFactorSourceDetail

struct DeviceFactorSourceDetail: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let factorSource: DeviceFactorSource
	}

	enum ViewAction: Sendable, Equatable {
		case renameTapped
		case viewSeedPhraseTapped
	}

	func reduce(into _: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .renameTapped, .viewSeedPhraseTapped:
			.none
		}
	}
}
