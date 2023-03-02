import CreateEntityFeature
import FeaturePrelude

// MARK: - ManageGatewayAPIEndpoints.Action
extension ManageGatewayAPIEndpoints {
	public enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case child(ChildAction)
		case delegate(DelegateAction)
	}
}

// MARK: - ManageGatewayAPIEndpoints.Action.ViewAction
extension ManageGatewayAPIEndpoints.Action {
	public enum ViewAction: Sendable, Equatable {
		case didAppear
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
		case loadGatewayResult(TaskResult<Gateway>)
		/// Nil if no change was needed
		case gatewayValidationResult(TaskResult<Gateway?>)
		case hasAccountsResult(TaskResult<Bool>)
		case createAccountOnNetworkBeforeSwitchingToIt(Gateway)
		case switchToResult(TaskResult<Gateway>)
	}
}

// MARK: - ManageGatewayAPIEndpoints.Action.ChildAction
extension ManageGatewayAPIEndpoints.Action {
	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationActionOf<ManageGatewayAPIEndpoints.Destinations>)
	}
}

// MARK: - ManageGatewayAPIEndpoints.Action.DelegateAction
extension ManageGatewayAPIEndpoints.Action {
	public enum DelegateAction: Sendable, Equatable {
		case networkChanged
	}
}
