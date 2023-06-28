import FeaturePrelude

// MARK: - UpdateSecurityStateOfEntityCoordinator
public struct UpdateSecurityStateOfEntityCoordinator<Entity: EntityProtocol & Sendable & Hashable>: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let entity: Entity
		public init(entity: Entity) {
			self.entity = entity
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

extension UpdateSecurityStateOfEntityCoordinator.State where Entity == Profile.Network.Account {
	public init(account: Entity) {
		self.init(entity: account)
	}
}

extension UpdateSecurityStateOfEntityCoordinator.State where Entity == Profile.Network.Persona {
	public init(persona: Entity) {
		self.init(entity: persona)
	}
}
