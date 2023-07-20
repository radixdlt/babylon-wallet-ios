import FeaturePrelude
import Profile

struct PersonaDataPermissionBox: Sendable, FeatureReducer {
	struct State: Sendable, Hashable, Identifiable {
		var id: Profile.Network.Persona.ID { persona.id }
		let persona: Profile.Network.Persona
		let requested: P2P.Dapp.Request.PersonaDataRequestItem
		let issues: [PersonaData.Entry.Kind: P2P.Dapp.Request.Issue]

		init(
			persona: Profile.Network.Persona,
			requested: P2P.Dapp.Request.PersonaDataRequestItem
		) {
			self.persona = persona
			self.requested = requested
			self.issues = persona.personaData.requestIssues(requested)

			print("••••• ISSUES •••••")
			for (entry, issue) in issues {
				print("•• \(entry.title): \(issue)")
			}
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
