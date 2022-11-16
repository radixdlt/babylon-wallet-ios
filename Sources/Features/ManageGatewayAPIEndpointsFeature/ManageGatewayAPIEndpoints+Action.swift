import ComposableArchitecture
import Foundation

// MARK: - ManageGatewayAPIEndpoints.Action
public extension ManageGatewayAPIEndpoints {
	enum Action: Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - ManageGatewayAPIEndpoints.Action.ViewAction
public extension ManageGatewayAPIEndpoints.Action {
	enum ViewAction: Equatable {
		case dismissButtonTapped
		case gatewayAPIURLChanged(String)
		case switchToButtonTapped
	}
}

// MARK: - ManageGatewayAPIEndpoints.Action.InternalAction
public extension ManageGatewayAPIEndpoints.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - ManageGatewayAPIEndpoints.Action.SystemAction
public extension ManageGatewayAPIEndpoints.Action {
	enum SystemAction: Equatable {
		case setGatewayAPIEndpointResult(TaskResult<URL>)
	}
}

// MARK: - ManageGatewayAPIEndpoints.Action.DelegateAction
public extension ManageGatewayAPIEndpoints.Action {
	enum DelegateAction: Equatable {
		case dismiss
		case successfullyUpdatedGatewayAPIEndpoint
	}
}
