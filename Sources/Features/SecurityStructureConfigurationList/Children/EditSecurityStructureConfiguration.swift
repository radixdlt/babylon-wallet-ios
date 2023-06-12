import FeaturePrelude

// MARK: - EditSecurityStructureConfiguration
public struct EditSecurityStructureConfiguration: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = SecurityStructureConfiguration
		public var id: ID { config }
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
