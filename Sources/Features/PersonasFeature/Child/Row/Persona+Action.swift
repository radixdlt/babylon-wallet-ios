import FeaturePrelude

// MARK: - Persona.Action
extension Persona {
	public enum Action: Sendable, Equatable {
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

extension Persona.Action {
	public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - Persona.Action.ViewAction
extension Persona.Action {
	public enum ViewAction: Sendable, Equatable {
		case appeared
	}
}

// MARK: - Persona.Action.InternalAction
extension Persona.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - Persona.Action.SystemAction
extension Persona.Action {
	public enum SystemAction: Sendable, Equatable {}
}

// MARK: - Persona.Action.DelegateAction
extension Persona.Action {
	public enum DelegateAction: Sendable, Equatable {}
}
