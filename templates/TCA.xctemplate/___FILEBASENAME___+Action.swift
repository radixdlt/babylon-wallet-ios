import Foundation

// MARK: - ___VARIABLE_moduleName___.Action
public extension ___VARIABLE_moduleName___ {
	enum Action: Equatable {
		case view(ViewAction)
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
	enum InternalAction: Equatable {}
}

// MARK: - ___VARIABLE_moduleName___.Action.DelegateAction
public extension ___VARIABLE_moduleName___.Action {
	enum DelegateAction: Equatable {}
}
