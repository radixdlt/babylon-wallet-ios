import Foundation

public extension Home {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalActions)
		case coordinate(CoordinatingAction)
	}
}

public extension Home.Action {
	enum InternalActions: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension Home.Action.InternalActions {
	enum UserAction: Equatable {
		case toggleWalletVisibility
		case walletToggleIsPressed
		case settingsButtonTapped
		case createNewAccountButtonIsPressed
		case visitTheRadixHubIsPressed
	}
}

public extension Home.Action.InternalActions {
	enum SystemAction: Equatable {}
}

public extension Home.Action {
	enum CoordinatingAction: Equatable {}
}
