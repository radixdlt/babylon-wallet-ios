import HomeFeature
import SettingsFeature

// MARK: - Main.Action
public extension Main {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case home(Home.Action)
		case settings(Settings.Action)
	}
}

// MARK: - Main.Action.InternalAction
public extension Main.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

// MARK: - Main.Action.InternalAction.UserAction
public extension Main.Action.InternalAction {
	enum UserAction: Equatable {
		case removeWallet
	}
}

// MARK: - Main.Action.InternalAction.SystemAction
public extension Main.Action.InternalAction {
	enum SystemAction: Equatable {
		case removedWallet
	}
}

// MARK: - Main.Action.CoordinatingAction
public extension Main.Action {
	enum CoordinatingAction: Equatable {
		case removedWallet
	}
}
