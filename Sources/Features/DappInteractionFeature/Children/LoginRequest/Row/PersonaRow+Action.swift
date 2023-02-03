import FeaturePrelude

// MARK: - PersonaRow.Action
extension PersonaRow {
	enum Action: Sendable, Equatable {
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

extension PersonaRow.Action {
	static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - PersonaRow.Action.ViewAction
extension PersonaRow.Action {
	enum ViewAction: Sendable, Equatable {
		case didSelect
	}
}

// MARK: - PersonaRow.Action.InternalAction
extension PersonaRow.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - PersonaRow.Action.SystemAction
extension PersonaRow.Action {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - PersonaRow.Action.DelegateAction
extension PersonaRow.Action {
	enum DelegateAction: Sendable, Equatable {}
}
