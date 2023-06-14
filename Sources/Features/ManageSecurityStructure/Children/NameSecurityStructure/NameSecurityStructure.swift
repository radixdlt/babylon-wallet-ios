import AppPreferencesClient
import FeaturePrelude

// MARK: - NameSecurityStructure
public struct NameSecurityStructure: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let config: SecurityStructureConfiguration.Configuration
		public var name: String
		public let createdOn: Date
		public let isUpdatingExisting: Bool
		public init(config: SecurityStructureConfiguration.Configuration, name: String, createdOn: Date, isUpdatingExisting: Bool) {
			self.config = config
			self.name = name
			self.createdOn = createdOn
			self.isUpdatingExisting = isUpdatingExisting
		}

		public static func name(new config: SecurityStructureConfiguration.Configuration) -> Self {
			@Dependency(\.date) var date
			return Self(config: config, name: "", createdOn: date(), isUpdatingExisting: false)
		}

		public static func updateName(of structure: SecurityStructureConfiguration) -> Self {
			Self(
				config: structure.configuration,
				name: structure.label.rawValue,
				createdOn: structure.createdOn,
				isUpdatingExisting: true
			)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case nameChanged(String)
		case confirmedName(NonEmptyString)
	}

	public enum DelegateAction: Sendable, Equatable {
		case securityStructureUpdatedOrCreatedResult(TaskResult<SecurityStructureConfiguration>)
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
				configuration: state.config,
				createdOn: state.createdOn
			)
			return .task { [isUpdatingExisting = state.isUpdatingExisting] in
				let taskResult = await TaskResult {
					try await appPreferencesClient.updating { preferences in
						let didUpdateExisting = preferences.security.structureConfigurations.updateOrAppend(config) != nil
						assert(didUpdateExisting == isUpdatingExisting)
					}
					return config
				}
				return .delegate(.securityStructureUpdatedOrCreatedResult(taskResult))
			}
		}
	}
}
