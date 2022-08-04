import Common
import ComposableArchitecture
import Foundation
import Profile
import UserDefaultsClient
import Wallet

public extension Onboarding {
	// MARK: Action
	enum Action: Equatable, BindableAction {
		case binding(BindingAction<State>)
		case coordinate(CoordinatingAction)
		case `internal`(InternalAction)
	}
}

public extension Onboarding.Action {
	enum CoordinatingAction: Equatable {
		case onboardedWithWallet(Wallet)
	}
}

public extension Onboarding.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension Onboarding.Action.InternalAction {
	enum UserAction: Equatable {
		case createWallet
	}
}

public extension Onboarding.Action.InternalAction {
	enum SystemAction: Equatable {
		case createWallet
		case createWalletResult(Result<Wallet, Never>)
	}
}
