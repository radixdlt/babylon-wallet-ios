import AppPreferencesClient
import FeaturePrelude

// MARK: - SecurityStructureConfigurationList
public struct SecurityStructureConfigurationList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Context: Sendable, Hashable {
			case settings
			/// Use it
			case securifyEntity
		}

		public let context: Context
		public var selectedConfig: SecurityStructureConfigurationReference? = nil
		public var configs: IdentifiedArrayOf<SecurityStructureConfigurationRow.State>

		public init(
			context: Context,
			configs: IdentifiedArrayOf<SecurityStructureConfigurationRow.State> = []
		) {
			self.context = context
			self.configs = configs
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case createNewStructure
		case selectedConfig(SecurityStructureConfigurationReference?)
		case confirmedSelectedConfig(SecurityStructureConfigurationReference)
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
		case selectedConfig(SecurityStructureConfigurationReference)
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
				let configs = await appPreferencesClient.getPreferences().security.structureConfigurationReferences
				return .internal(.configsLoaded(.init(
					uncheckedUniqueElements: configs.map(SecurityStructureConfigurationRow.State.init))
				))
			}

		case let .selectedConfig(config):
			state.selectedConfig = config
			return .none

		case let .confirmedSelectedConfig(config):
			return .send(.delegate(.selectedConfig(config)))

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
