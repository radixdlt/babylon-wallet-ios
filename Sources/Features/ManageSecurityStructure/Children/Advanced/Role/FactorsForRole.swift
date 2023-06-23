import FeaturePrelude

// MARK: - FactorsForRole
public struct FactorsForRole<RoleKind: RoleProtocol>: Sendable, FeatureReducer {
	public typealias Role = RoleOfTier<RoleKind, FactorSource>
	public struct State: Sendable, Hashable {
		public var role: Role

		public init(role: Role) {
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
