import FeaturePrelude

// MARK: - SecurityStructureConfigurationRow
public struct SecurityStructureConfigurationRow: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = SecurityStructureConfigurationReference.ID
		public var id: ID { configReference.id }
		public let configReference: SecurityStructureConfigurationReference
		public init(configReference: SecurityStructureConfigurationReference) {
			self.configReference = configReference
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case displayDetails
	}

	public enum DelegateAction: Sendable, Equatable {
		case displayDetails
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .displayDetails:
			return .send(.delegate(.displayDetails))
		}
	}
}
