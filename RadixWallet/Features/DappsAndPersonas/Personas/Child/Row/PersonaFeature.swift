import ComposableArchitecture
import SwiftUI

// MARK: - Persona
struct PersonaFeature: Sendable, FeatureReducer {
	struct State: Sendable, Hashable, Identifiable {
		let id: Persona.ID
		let thumbnail: URL?
		let displayName: String
		var securityProblemsConfig: EntitySecurityProblemsView.Config

		init(persona: AuthorizedPersonaDetailed, problems: [SecurityProblem]) {
			self.init(
				id: persona.id,
				thumbnail: nil,
				displayName: persona.displayName.rawValue,
				identityAddress: persona.identityAddress,
				problems: problems
			)
		}

		init(persona: Persona, problems: [SecurityProblem]) {
			self.init(
				id: persona.id,
				thumbnail: nil,
				displayName: persona.displayName.rawValue,
				identityAddress: persona.address,
				problems: problems
			)
		}

		init(
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

	enum ViewAction: Sendable, Equatable {
		case tapped
		case securityProblemsTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case openDetails
		case openSecurityCenter
	}

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .tapped:
			.send(.delegate(.openDetails))
		case .securityProblemsTapped:
			.send(.delegate(.openSecurityCenter))
		}
	}
}
