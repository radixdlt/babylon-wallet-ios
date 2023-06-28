import FeaturePrelude
import SecurityStructureConfigurationListFeature

// MARK: - UpdateSecurityStateOfEntityCoordinator
public struct UpdateSecurityStateOfEntityCoordinator<Entity: EntityProtocol & Sendable & Hashable>: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let entity: Entity

		public var root: Path.State
		public var path: StackState<Path.State> = .init()

		public init(entity: Entity) {
			self.entity = entity
			self.root = .selectSecurityStructureConfig(.init(
				configList: .init(context: .securifyEntity)
			))
		}
	}

	public struct Path: Sendable, Hashable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case selectSecurityStructureConfig(SecurityStructureConfigurationListCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case selectSecurityStructureConfig(SecurityStructureConfigurationListCoordinator.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.selectSecurityStructureConfig, action: /Action.selectSecurityStructureConfig) {
				SecurityStructureConfigurationListCoordinator()
			}
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case root(Path.Action)
		case path(StackActionOf<Path>)
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.root, action: /Action.child .. ChildAction.root) {
			Path()
		}

		Reduce(core)
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
	}

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
