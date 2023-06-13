import FeaturePrelude

// MARK: - SecurityStructureConfigDetails
public struct SecurityStructureConfigDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let config: SecurityStructureConfiguration
		public init(config: SecurityStructureConfiguration) {
			self.config = config
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}
