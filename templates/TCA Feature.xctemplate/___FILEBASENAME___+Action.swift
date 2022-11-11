import Foundation

// MARK: - ___VARIABLE_featureName___.Action
public extension ___VARIABLE_featureName___ {
	enum Action: Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - ___VARIABLE_featureName___.Action.ViewAction
public extension ___VARIABLE_featureName___.Action {
	enum ViewAction: Equatable {}
}

// MARK: - ___VARIABLE_featureName___.Action.InternalAction
public extension ___VARIABLE_featureName___.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - ___VARIABLE_featureName___.Action.SystemAction
public extension ___VARIABLE_featureName___.Action {
	enum SystemAction: Equatable {}
}

// MARK: - ___VARIABLE_featureName___.Action.DelegateAction
public extension ___VARIABLE_featureName___.Action {
	enum DelegateAction: Equatable {}
}
