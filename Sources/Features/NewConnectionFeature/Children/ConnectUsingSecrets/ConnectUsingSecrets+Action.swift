import FeaturePrelude
import P2PConnection

// MARK: - ConnectUsingSecrets.Action
extension ConnectUsingSecrets {
	public enum Action: Sendable, Equatable {
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

extension ConnectUsingSecrets.Action {
	public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - ConnectUsingSecrets.Action.ViewAction
extension ConnectUsingSecrets.Action {
	public enum ViewAction: Sendable, Equatable {
		case task
		case appeared
		case nameOfConnectionChanged(String)
		case confirmNameButtonTapped
		case textFieldFocused(ConnectUsingSecrets.State.Field?)
	}
}

// MARK: - ConnectUsingSecrets.Action.InternalAction
extension ConnectUsingSecrets.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - ConnectUsingSecrets.Action.SystemAction
extension ConnectUsingSecrets.Action {
	public enum SystemAction: Sendable, Equatable {
		case focusTextField(ConnectUsingSecrets.State.Field?)
		case establishConnectionResult(TaskResult<P2PConnectionID>)
	}
}

// MARK: - ConnectUsingSecrets.Action.DelegateAction
extension ConnectUsingSecrets.Action {
	public enum DelegateAction: Sendable, Equatable {
		case connected(P2P.ClientWithConnectionStatus)
	}
}
