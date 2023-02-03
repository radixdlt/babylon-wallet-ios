import FeaturePrelude

// MARK: - PersonaList.Action
public extension PersonaList {
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

public extension PersonaList.Action {
	static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - PersonaList.Action.ChildAction
public extension PersonaList.Action {
	enum ChildAction: Sendable, Equatable {
		case persona(
			id: OnNetwork.Persona.ID,
			action: Persona.Action
		)
	}
}

// MARK: - PersonaList.Action.ViewAction
public extension PersonaList.Action {
	enum ViewAction: Sendable, Equatable {
		case dismissButtonTapped
		case createNewPersonaButtonTapped
	}
}

// MARK: - PersonaList.Action.InternalAction
public extension PersonaList.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - PersonaList.Action.SystemAction
public extension PersonaList.Action {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - PersonaList.Action.DelegateAction
public extension PersonaList.Action {
	enum DelegateAction: Sendable, Equatable {
		case createNewPersona
		case dismiss
	}
}
