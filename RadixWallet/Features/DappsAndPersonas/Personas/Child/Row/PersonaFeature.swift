import ComposableArchitecture
import SwiftUI

// MARK: - Persona
public struct PersonaFeature: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public let id: Persona.ID
		public let thumbnail: URL?
		public let displayName: String
		public var securityProblemsConfig: EntitySecurityProblemsView.Config

		public init(persona: AuthorizedPersonaDetailed, problems: [SecurityProblem]) {
			self.init(
				id: persona.id,
				thumbnail: nil,
				displayName: persona.displayName.rawValue,
				identityAddress: persona.identityAddress,
				problems: problems
			)
		}

		public init(persona: Persona, problems: [SecurityProblem]) {
			self.init(
				id: persona.id,
				thumbnail: nil,
				displayName: persona.displayName.rawValue,
				identityAddress: persona.address,
				problems: problems
			)
		}

		public init(
			id: Persona.ID,
			thumbnail: URL?,
			displayName: String,
			identityAddress: IdentityAddress,
			problems: [SecurityProblem]
		) {
			self.id = id
			self.thumbnail = thumbnail
			self.displayName = displayName
			self.securityProblemsConfig = .init(kind: .persona(identityAddress), problems: problems)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case tapped
		case securityProblemsTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case openDetails
		case openSecurityCenter
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .tapped:
			.send(.delegate(.openDetails))
		case .securityProblemsTapped:
			.send(.delegate(.openSecurityCenter))
		}
	}
}
