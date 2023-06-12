import AppPreferencesClient
import FeaturePrelude

// MARK: - SecurityStructureConfigurationList
public struct SecurityStructureConfigurationList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var configs: IdentifiedArrayOf<EditSecurityStructureConfiguration.State> = []
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case createNewStructure
	}

	public enum ChildAction: Sendable, Equatable {
		case config(id: EditSecurityStructureConfiguration.State.ID, action: EditSecurityStructureConfiguration.Action)
	}

	public enum InternalAction: Sendable, Equatable {
		case configsLoaded(IdentifiedArrayOf<EditSecurityStructureConfiguration.State>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case createNewStructure
	}

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	public init() {}

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
}
