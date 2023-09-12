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
		case displayDetails(SecurityStructureConfigurationReference)
	}

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	public init() {}

	public var body: some ReducerOf<Self> {
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
			return .run { send in
				let configs = await appPreferencesClient.getPreferences().security.structureConfigurationReferences
				await send(.internal(.configsLoaded(.init(
					uncheckedUniqueElements: configs.map(SecurityStructureConfigurationRow.State.init))
				)))
			}
		case .createNewStructure:
			return .send(.delegate(.createNewStructure))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .config(id, action: .delegate(.displayDetails)):
			guard let configState = state.configs[id: id] else {
				assertionFailure("did not find config state")
				return .none
			}
			return .send(.delegate(.displayDetails(configState.configReference)))
		default: return .none
		}
	}
}
