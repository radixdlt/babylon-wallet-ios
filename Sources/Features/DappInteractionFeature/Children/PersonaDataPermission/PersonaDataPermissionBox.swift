import FeaturePrelude
import Profile

struct PersonaDataPermissionBox: Sendable, FeatureReducer {
	struct State: Sendable, Hashable, Identifiable {
		var id: Profile.Network.Persona.ID { persona.id }
		let persona: Profile.Network.Persona
		let requested: PersonaDataPermission.Request
		let response: PersonaDataPermission.Response.Result

		init(
			persona: Profile.Network.Persona,
			requested: PersonaDataPermission.Request
		) {
			self.persona = persona
			self.requested = requested
			self.response = .init(request: requested, personaData: persona.personaData)
		}
	}

	enum ViewAction: Sendable, Equatable {
		case editButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case edit
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .editButtonTapped:
			return .send(.delegate(.edit))
		}
	}
}
