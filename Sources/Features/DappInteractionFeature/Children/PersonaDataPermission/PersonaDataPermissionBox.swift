import FeaturePrelude
import Profile

struct PersonaDataPermissionBox: Sendable, FeatureReducer {
	struct State: Sendable, Hashable, Identifiable {
		var id: Profile.Network.Persona.ID { persona.id }
		let persona: Profile.Network.Persona
		let allRequiredFieldIDs: Set<Profile.Network.Persona.Field.ID>
		let missingRequiredFieldIDs: NonEmptySet<Profile.Network.Persona.Field.ID>?

		init(
			persona: Profile.Network.Persona,
			requiredFieldIDs: Set<Profile.Network.Persona.Field.ID>
		) {
			self.persona = persona
			self.allRequiredFieldIDs = requiredFieldIDs
			self.missingRequiredFieldIDs = NonEmptySet(rawValue: requiredFieldIDs.subtracting(persona.fields.map(\.id)))
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
