import ComposableArchitecture
import Wallet

// MARK: - Onboarding.Action
public extension Onboarding {
	// MARK: Action
	enum Action: Equatable, BindableAction {
		case binding(BindingAction<State>)
		case coordinate(CoordinatingAction)
		case `internal`(InternalAction)
	}
}

// MARK: - Onboarding.Action.CoordinatingAction
public extension Onboarding.Action {
	enum CoordinatingAction: Equatable {
		case onboardedWithWallet(Wallet)
	}
}

// MARK: - Onboarding.Action.InternalAction
public extension Onboarding.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

// MARK: - Onboarding.Action.InternalAction.UserAction
public extension Onboarding.Action.InternalAction {
	enum UserAction: Equatable {
		case createWallet
	}
}

// MARK: - Onboarding.Action.InternalAction.SystemAction
public extension Onboarding.Action.InternalAction {
	enum SystemAction: Equatable {
		case createWallet
		case createdWallet(Wallet)
	}
}
