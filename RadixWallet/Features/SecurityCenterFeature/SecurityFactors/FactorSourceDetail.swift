// MARK: - DeviceFactorSourceDetail

struct FactorSourceDetail: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let integrity: FactorSourceIntegrity

		var factorSource: FactorSource {
			integrity.factorSource
		}
	}

	enum ViewAction: Sendable, Equatable {
		case renameTapped
		case viewSeedPhraseTapped
		case changePinTapped
	}

	func reduce(into _: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .renameTapped, .viewSeedPhraseTapped, .changePinTapped:
			.none
		}
	}
}
