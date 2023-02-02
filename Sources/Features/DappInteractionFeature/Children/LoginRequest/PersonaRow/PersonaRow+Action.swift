import FeaturePrelude

// MARK: - PersonaRow.Action
public extension PersonaRow {
	enum Action: Sendable, Equatable {
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

public extension PersonaRow.Action {
	static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - PersonaRow.Action.ViewAction
public extension PersonaRow.Action {
	enum ViewAction: Sendable, Equatable {
		case didSelect
	}
}

// MARK: - PersonaRow.Action.InternalAction
public extension PersonaRow.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - PersonaRow.Action.SystemAction
public extension PersonaRow.Action {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - PersonaRow.Action.DelegateAction
public extension PersonaRow.Action {
	enum DelegateAction: Sendable, Equatable {}
}
