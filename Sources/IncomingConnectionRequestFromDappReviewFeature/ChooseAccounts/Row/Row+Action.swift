import Foundation

public extension ChooseAccounts.Row {
    enum Action: Equatable {
        case `internal`(InternalAction)
        case coordinate(CoordinatingAction)
    }
}

public extension ChooseAccounts.Row.Action {
    enum InternalAction: Equatable {
        case user(UserAction)
        case system(SystemAction)
    }
}

public extension ChooseAccounts.Row.Action.InternalAction {
    enum UserAction: Equatable {
        case accountTapped
    }
}

public extension ChooseAccounts.Row.Action.InternalAction {
    enum SystemAction: Equatable {}
}

public extension ChooseAccounts.Row.Action {
    enum CoordinatingAction: Equatable {}
}
