import AppPreferencesClient
import FeaturePrelude

// MARK: - SecurityStructureConfigs
public struct SecurityStructureConfigs: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@Loadable
		public var configs: OrderedSet<SecurityStructureConfiguration>? = nil

		public init() {}
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedConfigs(OrderedSet<SecurityStructureConfiguration>)
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
	}

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .onFirstTask:
			return .task {
				await .internal(.loadedConfigs(
					appPreferencesClient.getPreferences().security.structureConfigurations
				))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadedConfigs(configs):
		}
	}
}
