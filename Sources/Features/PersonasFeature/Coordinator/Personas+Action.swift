import FeaturePrelude

// MARK: - Personas.Action
public extension Personas {
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

public extension Personas.Action {
	static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - Personas.Action.ChildAction
public extension Personas.Action {
	enum ChildAction: Sendable, Equatable {
		case persona(
			id: OnNetwork.Persona.ID,
			action: Persona.Action
		)
	}
}

// MARK: - Personas.Action.ViewAction
public extension Personas.Action {
	enum ViewAction: Sendable, Equatable {
		case dismissButtonTapped
		case createNewPersonaButtonTapped
	}
}

// MARK: - Personas.Action.InternalAction
public extension Personas.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - Personas.Action.SystemAction
public extension Personas.Action {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - Personas.Action.DelegateAction
public extension Personas.Action {
	enum DelegateAction: Sendable, Equatable {
		case dismiss
	}
}
