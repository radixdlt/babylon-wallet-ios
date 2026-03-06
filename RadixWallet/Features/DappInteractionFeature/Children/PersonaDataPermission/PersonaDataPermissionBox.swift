import ComposableArchitecture
import SwiftUI

struct PersonaDataPermissionBox: FeatureReducer {
	struct State: Hashable, Identifiable {
		var id: Persona.ID {
			persona.id
		}

		let persona: Persona
		let requested: DappToWalletInteractionPersonaDataRequestItem
		let responseValidation: DappToWalletInteraction.RequestValidation

		init(
			persona: Persona,
			requested: DappToWalletInteractionPersonaDataRequestItem
		) {
			self.persona = persona
			self.requested = requested
			self.responseValidation = persona.personaData.responseValidation(for: requested)
		}
	}

	enum ViewAction: Equatable {
		case editButtonTapped
	}

	enum DelegateAction: Equatable {
		case edit
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .editButtonTapped:
			.send(.delegate(.edit))
		}
	}
}
