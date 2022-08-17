import Common
import ComposableArchitecture
import CreateAccount
import Foundation
import HomeFeature
import SettingsFeature
import UserDefaultsClient
import Wallet

public extension Main {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalActions)
		case coordinate(CoordinatingAction)
		case home(Home.Action)
		case settings(Settings.Action)
		case createAccount(CreateAccount.Action)
	}
}

public extension Main.Action {
	enum InternalActions: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension Main.Action.InternalActions {
	enum UserAction: Equatable {
		case removeWallet
	}
}

public extension Main.Action.InternalActions {
	enum SystemAction: Equatable {
		case removedWallet
	}
}

public extension Main.Action {
	enum CoordinatingAction: Equatable {
		case removedWallet
	}
}
