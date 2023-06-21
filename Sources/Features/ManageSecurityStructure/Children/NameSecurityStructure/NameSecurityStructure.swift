import AppPreferencesClient
import FeaturePrelude

// MARK: - NameSecurityStructure
public struct NameSecurityStructure: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let id: SecurityStructureConfigurationDetailed.ID
		public let config: SecurityStructureConfigurationDetailed.Configuration
		public var name: String
		public let createdOn: Date
		public let isUpdatingExisting: Bool

		public init(
			id: SecurityStructureConfigurationDetailed.ID,
			config: SecurityStructureConfigurationDetailed.Configuration,
			name: String,
			createdOn: Date,
			isUpdatingExisting: Bool
		) {
			self.id = id
			self.config = config
			self.name = name
			self.createdOn = createdOn
			self.isUpdatingExisting = isUpdatingExisting
		}

		public static func name(
			new config: SecurityStructureConfigurationDetailed.Configuration
		) -> Self {
			@Dependency(\.uuid) var uuid
			@Dependency(\.date) var date
			return Self(
				id: uuid(),
				config: config,
				name: "",
				createdOn: date(),
				isUpdatingExisting: false
			)
		}

		public static func updateName(of structure: SecurityStructureConfigurationDetailed) -> Self {
			Self(
				id: structure.id,
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
		case updateOrCreateSecurityStructure(SecurityStructureConfigurationDetailed)
	}

	@Dependency(\.date) var date
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .nameChanged(name):
			state.name = name
			return .none
		case let .confirmedName(name):
			let structure = SecurityStructureConfigurationDetailed(
				id: state.id,
				label: name,
				configuration: state.config,
				createdOn: state.createdOn,
				lastUpdatedOn: date()
			)

			return .send(.delegate(.updateOrCreateSecurityStructure(structure)))
		}
	}
}
