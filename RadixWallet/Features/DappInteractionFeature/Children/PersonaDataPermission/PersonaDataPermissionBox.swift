import ComposableArchitecture
import SwiftUI

struct PersonaDataPermissionBox: Sendable, FeatureReducer {
	struct State: Sendable, Hashable, Identifiable {
		var id: Persona.ID { persona.id }
		let persona: Persona
		let requested: P2P.Dapp.Request.PersonaDataRequestItem
		let responseValidation: P2P.Dapp.Request.RequestValidation

		init(
			persona: Persona,
			requested: P2P.Dapp.Request.PersonaDataRequestItem
		) {
			self.persona = persona
			self.requested = requested
			self.responseValidation = persona.personaData.responseValidation(for: requested)
		}
	}

	enum ViewAction: Sendable, Equatable {
		case editButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case edit
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .editButtonTapped:
			.send(.delegate(.edit))
		}
	}
}
