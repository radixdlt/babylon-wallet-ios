import FeaturePrelude

// MARK: - SecurityStructureConfigurationRow
public struct SecurityStructureConfigurationRow: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = SecurityStructureConfiguration
		public var id: ID { config }
		public let config: SecurityStructureConfiguration
		public init(config: SecurityStructureConfiguration) {
			self.config = config
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case displayDetails
	}

	public enum DelegateAction: Sendable, Equatable {
		case displayDetails
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .displayDetails:
			return .send(.delegate(.displayDetails))
		}
	}
}
