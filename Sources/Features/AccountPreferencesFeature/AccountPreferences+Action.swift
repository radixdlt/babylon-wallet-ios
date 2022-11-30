import ComposableArchitecture
import Foundation
import Profile

// MARK: - AccountPreferences.Action
public extension AccountPreferences {
	// MARK: Action
	enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - AccountPreferences.Action.ViewAction
public extension AccountPreferences.Action {
	enum ViewAction: Sendable, Equatable {
		case didAppear
		case dismissButtonTapped
		case faucetButtonTapped
	}
}

// MARK: - AccountPreferences.Action.InternalAction
public extension AccountPreferences.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - AccountPreferences.Action.SystemAction
public extension AccountPreferences.Action {
	enum SystemAction: Sendable, Equatable {
		case isAllowedToUseFaucet(TaskResult<Bool>)
		case disableGetFreeXRDButton
	}
}

// MARK: - AccountPreferences.Action.DelegateAction
public extension AccountPreferences.Action {
	enum DelegateAction: Sendable, Equatable {
		case dismissAccountPreferences
		case refreshAccount(AccountAddress)
	}
}
