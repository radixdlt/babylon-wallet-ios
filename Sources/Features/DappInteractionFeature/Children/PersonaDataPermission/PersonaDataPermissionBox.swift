import FeaturePrelude
import Profile

struct PersonaDataPermissionBox: Sendable, FeatureReducer {
	struct State: Sendable, Hashable, Identifiable {
		var id: Profile.Network.Persona.ID { persona.id }
		let persona: Profile.Network.Persona
		let requested: P2P.Dapp.Request.PersonaDataRequestItem
		let result: P2P.Dapp.Request.ResponseResult

		init(
			persona: Profile.Network.Persona,
			requested: P2P.Dapp.Request.PersonaDataRequestItem
		) {
			self.persona = persona
			self.requested = requested
			self.result = persona.personaData.response(for: requested)
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
