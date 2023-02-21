import CreateEntityFeature
import FeaturePrelude

// MARK: - ManageGatewayAPIEndpoints.Action
extension ManageGatewayAPIEndpoints {
	public enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)

		/// Child
		case createAccountCoordinator(CreateAccountCoordinator.Action)
	}
}

// MARK: - ManageGatewayAPIEndpoints.Action.ViewAction
extension ManageGatewayAPIEndpoints.Action {
	public enum ViewAction: Sendable, Equatable {
		case didAppear
		case dismissButtonTapped
		case urlStringChanged(String)
		case switchToButtonTapped
		case focusTextField(ManageGatewayAPIEndpoints.State.Field?)
	}
}

// MARK: - ManageGatewayAPIEndpoints.Action.InternalAction
extension ManageGatewayAPIEndpoints.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - ManageGatewayAPIEndpoints.Action.SystemAction
extension ManageGatewayAPIEndpoints.Action {
	public enum SystemAction: Sendable, Equatable {
		case loadNetworkAndGatewayResult(TaskResult<AppPreferences.NetworkAndGateway>)
		/// Nil if no change was needed
		case gatewayValidationResult(TaskResult<AppPreferences.NetworkAndGateway?>)
		case hasAccountsResult(TaskResult<Bool>)
		case createAccountOnNetworkBeforeSwitchingToIt(AppPreferences.NetworkAndGateway)
		case switchToResult(TaskResult<AppPreferences.NetworkAndGateway>)
	}
}

// MARK: - ManageGatewayAPIEndpoints.Action.DelegateAction
extension ManageGatewayAPIEndpoints.Action {
	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case networkChanged
	}
}
