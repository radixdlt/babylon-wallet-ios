import FeaturePrelude

// MARK: - LoginRequest.Action
public extension LoginRequest {
	enum Action: Sendable, Equatable {
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

public extension LoginRequest.Action {
	static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - LoginRequest.Action.ViewAction
public extension LoginRequest.Action {
	enum ViewAction: Sendable, Equatable {
		case appeared
	}
}

// MARK: - LoginRequest.Action.InternalAction
public extension LoginRequest.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - LoginRequest.Action.SystemAction
public extension LoginRequest.Action {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - LoginRequest.Action.DelegateAction
public extension LoginRequest.Action {
	enum DelegateAction: Sendable, Equatable {}
}
