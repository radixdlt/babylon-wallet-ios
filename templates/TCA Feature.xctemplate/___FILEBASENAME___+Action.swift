import Foundation

// MARK: - ___VARIABLE_moduleName___.Action
public extension ___VARIABLE_moduleName___ {
	enum Action: Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - ___VARIABLE_moduleName___.Action.ViewAction
public extension ___VARIABLE_moduleName___.Action {
	enum ViewAction: Equatable {}
}

// MARK: - ___VARIABLE_moduleName___.Action.InternalAction
public extension ___VARIABLE_moduleName___.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - ___VARIABLE_moduleName___.Action.SystemAction
public extension ___VARIABLE_moduleName___.Action {
	enum SystemAction: Equatable {}
}

// MARK: - ___VARIABLE_moduleName___.Action.DelegateAction
public extension ___VARIABLE_moduleName___.Action {
	enum DelegateAction: Equatable {}
}
