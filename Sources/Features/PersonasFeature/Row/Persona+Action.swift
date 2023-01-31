import FeaturePrelude

// MARK: - Persona.Action
public extension Persona {
	enum Action: Sendable, Equatable {
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

public extension Persona.Action {
	static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - Persona.Action.ViewAction
public extension Persona.Action {
	enum ViewAction: Sendable, Equatable {
		case appeared
	}
}

// MARK: - Persona.Action.InternalAction
public extension Persona.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - Persona.Action.SystemAction
public extension Persona.Action {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - Persona.Action.DelegateAction
public extension Persona.Action {
	enum DelegateAction: Sendable, Equatable {}
}
