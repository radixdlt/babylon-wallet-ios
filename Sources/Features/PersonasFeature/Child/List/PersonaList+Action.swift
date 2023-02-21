import FeaturePrelude

// MARK: - PersonaList.Action
extension PersonaList {
	public enum Action: Sendable, Equatable {
		case child(ChildAction)
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

extension PersonaList.Action {
	public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - PersonaList.Action.ChildAction
extension PersonaList.Action {
	public enum ChildAction: Sendable, Equatable {
		case persona(
			id: OnNetwork.Persona.ID,
			action: Persona.Action
		)
	}
}

// MARK: - PersonaList.Action.ViewAction
extension PersonaList.Action {
	public enum ViewAction: Sendable, Equatable {
		case createNewPersonaButtonTapped
	}
}

// MARK: - PersonaList.Action.InternalAction
extension PersonaList.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - PersonaList.Action.SystemAction
extension PersonaList.Action {
	public enum SystemAction: Sendable, Equatable {}
}

// MARK: - PersonaList.Action.DelegateAction
extension PersonaList.Action {
	public enum DelegateAction: Sendable, Equatable {
		case createNewPersona
	}
}
