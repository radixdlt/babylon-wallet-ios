import FeaturePrelude
import Profile

struct PersonaDataPermissionBox: Sendable, FeatureReducer {
	struct State: Sendable, Hashable, Identifiable {
		var id: Profile.Network.Persona.ID { persona.id }
		let persona: Profile.Network.Persona
		let requiredFieldIDs: NonEmptySet<Profile.Network.Persona.Field.ID>?

		init(
			persona: Profile.Network.Persona,
			requiredFieldIDs: Set<Profile.Network.Persona.Field.ID>
		) {
			self.persona = persona
			self.requiredFieldIDs = NonEmptySet(rawValue: requiredFieldIDs.subtracting(persona.fields.map(\.id)))
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
