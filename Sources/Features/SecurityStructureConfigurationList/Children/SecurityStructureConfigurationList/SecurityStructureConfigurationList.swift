import AppPreferencesClient
import FeaturePrelude

// MARK: - SecurityStructureConfigurationList
public struct SecurityStructureConfigurationList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var configs: IdentifiedArrayOf<SecurityStructureConfigurationRow.State> = []
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case createNewStructure
	}

	public enum ChildAction: Sendable, Equatable {
		case config(id: SecurityStructureConfigurationRow.State.ID, action: SecurityStructureConfigurationRow.Action)
	}

	public enum InternalAction: Sendable, Equatable {
		case configsLoaded(IdentifiedArrayOf<SecurityStructureConfigurationRow.State>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case createNewStructure
		case displayDetails(SecurityStructureConfiguration)
	}

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.forEach(\.configs, action: /Action.child .. ChildAction.config) {
				SecurityStructureConfigurationRow()
			}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .configsLoaded(configs):
			state.configs = configs
			return .none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .task:
			return .task {
				let configs = await appPreferencesClient.getPreferences().security.structureConfigurations
				return .internal(.configsLoaded(.init(uncheckedUniqueElements: configs.map {
					.init(config: $0)
				})))
			}
		case .createNewStructure:
			return .send(.delegate(.createNewStructure))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .config(id, action: .delegate(.displayDetails)):
			guard let config = state.configs[id: id]?.config else {
				assertionFailure("Failed to find config. bad!")
				return .none
			}
			return .send(.delegate(.displayDetails(config)))
		default: return .none
		}
	}
}
