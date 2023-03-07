import FeaturePrelude

// MARK: - ManageP2PClient.Action
extension ManageP2PClient {
	public enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case delegate(DelegateAction)
		case `internal`(InternalAction)
	}
}

// MARK: - ManageP2PClient.Action.ViewAction
extension ManageP2PClient.Action {
	public enum ViewAction: Sendable, Equatable {
		case deleteConnectionButtonTapped
	}
}

extension ManageP2PClient.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
	}

	public enum DelegateAction: Sendable, Equatable {
		case deleteConnection
	}
}
