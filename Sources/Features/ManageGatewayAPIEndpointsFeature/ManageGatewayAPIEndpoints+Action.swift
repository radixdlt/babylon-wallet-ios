import ComposableArchitecture
import CreateAccountFeature
import Foundation
import Profile

// MARK: - ManageGatewayAPIEndpoints.Action
public extension ManageGatewayAPIEndpoints {
	enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)

		/// Child
		case createAccount(CreateAccount.Action)
	}
}

// MARK: - ManageGatewayAPIEndpoints.Action.ViewAction
public extension ManageGatewayAPIEndpoints.Action {
	enum ViewAction: Sendable, Equatable {
		case didAppear
		case dismissButtonTapped
		case urlStringChanged(String)
		case switchToButtonTapped
		case focusTextField(ManageGatewayAPIEndpoints.State.Field?)
	}
}

// MARK: - ManageGatewayAPIEndpoints.Action.InternalAction
public extension ManageGatewayAPIEndpoints.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - ManageGatewayAPIEndpoints.Action.SystemAction
public extension ManageGatewayAPIEndpoints.Action {
	enum SystemAction: Sendable, Equatable {
		case loadNetworkAndGatewayResult(TaskResult<AppPreferences.NetworkAndGateway>)
		/// Nil if no change was needed
		case gatewayValidationResult(TaskResult<AppPreferences.NetworkAndGateway?>)
		case hasAccountsResult(TaskResult<Bool>)
		case createAccountOnNetworkBeforeSwitchingToIt(AppPreferences.NetworkAndGateway)
		case switchToResult(TaskResult<AppPreferences.NetworkAndGateway>)
	}
}

// MARK: - ManageGatewayAPIEndpoints.Action.DelegateAction
public extension ManageGatewayAPIEndpoints.Action {
	enum DelegateAction: Sendable, Equatable {
		case dismiss
		case networkChanged
	}
}
