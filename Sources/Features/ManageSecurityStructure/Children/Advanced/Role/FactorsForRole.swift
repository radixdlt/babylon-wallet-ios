import FeaturePrelude

// MARK: - FactorsForRole
public struct FactorsForRole: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var role: SecurityStructureRole

		public init(role: SecurityStructureRole) {
			self.role = role
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared, setFactorsButtonTapped
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .setFactorsButtonTapped:
			debugPrint("Set factors tapped")
			return .none
		}
	}
}
