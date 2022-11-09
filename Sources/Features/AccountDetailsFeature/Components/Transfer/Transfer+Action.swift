import Foundation

// MARK: - AccountDetails.Transfer.Action
public extension AccountDetails.Transfer {
	// MARK: Action
	enum Action: Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - AccountDetails.Transfer.Action.ViewAction
public extension AccountDetails.Transfer.Action {
	enum ViewAction: Equatable {
		case dismissTransferButtonTapped
	}
}

// MARK: - AccountDetails.Transfer.Action.InternalAction
public extension AccountDetails.Transfer.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
	}
}

// MARK: - AccountDetails.Transfer.Action.DelegateAction
public extension AccountDetails.Transfer.Action {
	enum DelegateAction: Equatable {
		case dismissTransfer
	}
}
