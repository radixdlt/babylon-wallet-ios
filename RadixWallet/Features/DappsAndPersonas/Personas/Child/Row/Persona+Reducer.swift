import ComposableArchitecture
import SwiftUI

// MARK: - Persona
public struct Persona: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public let id: Profile.Network.Persona.ID
		public let thumbnail: URL?
		public let displayName: String
		public var shouldWriteDownSeedPhrase: Bool

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
				shouldWriteDownSeedPhrase: persona.shouldWriteDownSeedPhrase
			)
		}

		public init(
			id: Profile.Network.Persona.ID,
			thumbnail: URL?,
			displayName: String,
			shouldWriteDownSeedPhrase: Bool = false
		) {
			self.id = id
			self.thumbnail = thumbnail
			self.displayName = displayName
			self.shouldWriteDownSeedPhrase = shouldWriteDownSeedPhrase
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case tapped
		case writeDownSeedPhrasePromptTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case openDetails
		case writeDownSeedPhrase
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .tapped:
			.send(.delegate(.openDetails))
		case .writeDownSeedPhrasePromptTapped:
			.send(.delegate(.writeDownSeedPhrase))
		}
	}
}
