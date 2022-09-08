import Common
import ComposableArchitecture
import Foundation
import HomeFeature
import SettingsFeature
import UserDefaultsClient
import Wallet

public extension Main {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case home(Home.Action)
		case settings(Settings.Action)
	}
}

public extension Main.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension Main.Action.InternalAction {
	enum UserAction: Equatable {
		case removeWallet
	}
}

public extension Main.Action.InternalAction {
	enum SystemAction: Equatable {
		case removedWallet
	}
}

public extension Main.Action {
	enum CoordinatingAction: Equatable {
		case removedWallet
	}
}
