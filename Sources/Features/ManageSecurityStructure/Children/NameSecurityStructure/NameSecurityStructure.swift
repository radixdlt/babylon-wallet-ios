import AppPreferencesClient
import FeaturePrelude

// MARK: - NameSecurityStructure
public struct NameSecurityStructure: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let configuration: SecurityStructureConfiguration.Configuration
		public var name = ""
		public init(configuration: SecurityStructureConfiguration.Configuration) {
			self.configuration = configuration
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case nameChanged(String)
		case confirmedName(NonEmptyString)
	}

	public enum DelegateAction: Sendable, Equatable {
		case securityStructureCreationResult(TaskResult<SecurityStructureConfiguration>)
	}

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .nameChanged(name):
			state.name = name
			return .none
		case let .confirmedName(name):
			let config = SecurityStructureConfiguration(
				label: name,
				configuration: state.configuration
			)
			return .task {
				let taskResult = await TaskResult {
					try await appPreferencesClient.updating { preferences in
						let (wasInserted, _) = preferences.security.structureConfigurations.append(config)
						assert(wasInserted)
					}
					return config
				}
				return .delegate(.securityStructureCreationResult(taskResult))
			}
		}
	}
}
