import Foundation

// MARK: - ___VARIABLE_featureName___.Action
public extension ___VARIABLE_featureName___ {
	enum Action: Sendable, Equatable {
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

public extension ___VARIABLE_featureName___ {
	static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - ___VARIABLE_featureName___.Action.ViewAction
public extension ___VARIABLE_featureName___.Action {
	enum ViewAction: Sendable, Equatable {
		case appeared
	}
}

// MARK: - ___VARIABLE_featureName___.Action.InternalAction
public extension ___VARIABLE_featureName___.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - ___VARIABLE_featureName___.Action.SystemAction
public extension ___VARIABLE_featureName___.Action {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - ___VARIABLE_featureName___.Action.DelegateAction
public extension ___VARIABLE_featureName___.Action {
	enum DelegateAction: Sendable, Equatable {}
}
