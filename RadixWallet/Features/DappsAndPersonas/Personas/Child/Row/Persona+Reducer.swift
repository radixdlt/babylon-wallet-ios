import ComposableArchitecture
import SwiftUI

// MARK: - Persona
public struct Persona: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public let id: Profile.Network.Persona.ID
		public let thumbnail: URL?
		public let displayName: String
		public var shouldBackupSeedPhrase: Bool

		public init(persona: Profile.Network.AuthorizedPersonaDetailed) {
			self.init(
				id: persona.id,
				thumbnail: nil,
				displayName: persona.displayName.rawValue
			)
		}

		public init(persona: Profile.Network.Persona) {
			self.init(
				id: persona.id,
				thumbnail: nil,
				displayName: persona.displayName.rawValue,
				shouldBackupSeedPhrase: persona.shouldBackupSeedPhrase
			)
		}

		public init(id: Profile.Network.Persona.ID, thumbnail: URL?, displayName: String, shouldBackupSeedPhrase: Bool = false) {
			self.id = id
			self.thumbnail = thumbnail
			self.displayName = displayName
			self.shouldBackupSeedPhrase = shouldBackupSeedPhrase
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case tapped
		case backupSeedPhrasePromptTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case openDetails
		case backupSeedPhrase
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .tapped:
			.send(.delegate(.openDetails))
		case .backupSeedPhrasePromptTapped:
			.send(.delegate(.backupSeedPhrase))
		}
	}
}
