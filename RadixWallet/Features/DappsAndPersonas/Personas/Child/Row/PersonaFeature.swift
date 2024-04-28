import ComposableArchitecture
import SwiftUI

// MARK: - Persona
public struct PersonaFeature: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public let id: Persona.ID
		public let thumbnail: URL?
		public let displayName: String
		public var shouldWriteDownMnemonic: Bool

		public init(persona: AuthorizedPersonaDetailed) {
			self.init(
				id: persona.id,
				thumbnail: nil,
				displayName: persona.displayName.rawValue
			)
		}

		public init(persona: Persona) {
			self.init(
				id: persona.id,
				thumbnail: nil,
				displayName: persona.displayName.rawValue,
				shouldWriteDownMnemonic: persona.shouldWriteDownMnemonic
			)
		}

		public init(
			id: Persona.ID,
			thumbnail: URL?,
			displayName: String,
			shouldWriteDownMnemonic: Bool = false
		) {
			self.id = id
			self.thumbnail = thumbnail
			self.displayName = displayName
			self.shouldWriteDownMnemonic = shouldWriteDownMnemonic
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
