import ComposableArchitecture
import SwiftUI

// MARK: - NameSecurityStructure
public struct NameSecurityStructure: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let config: SecurityStructureConfigurationDetailed.Configuration
		public var metadata: SecurityStructureMetadata
		public let isUpdatingExisting: Bool

		public init(
			config: SecurityStructureConfigurationDetailed.Configuration,
			metadata: SecurityStructureMetadata,
			isUpdatingExisting: Bool
		) {
			self.config = config
			self.metadata = metadata
			self.isUpdatingExisting = isUpdatingExisting
		}

		public static func name(
			new config: SecurityStructureConfigurationDetailed.Configuration
		) -> Self {
			Self(
				config: config,
				metadata: .init(),
				isUpdatingExisting: false
			)
		}

		public static func updateName(of structure: SecurityStructureConfigurationDetailed) -> Self {
			Self(config: structure.configuration, metadata: structure.metadata, isUpdatingExisting: true)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case nameChanged(String)
		case confirmedName(NonEmptyString)
	}

	public enum DelegateAction: Sendable, Equatable {
		case updateOrCreateSecurityStructure(SecurityStructureConfigurationDetailed)
	}

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .nameChanged(name):
			state.metadata.label = name
			return .none
		case let .confirmedName(name):
			var structure = SecurityStructureConfigurationDetailed(metadata: state.metadata, configuration: state.config)
			structure.metadata.label = name.rawValue
			structure.metadata.lastUpdatedOn = .init()
			return .send(.delegate(.updateOrCreateSecurityStructure(structure)))
		}
	}
}
