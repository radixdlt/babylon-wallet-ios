import AssetsViewFeature
import Profile

// MARK: - AccountDetails.Action
public extension AccountDetails {
	// MARK: Action
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - AccountDetails.Action.ChildAction
public extension AccountDetails.Action {
	enum ChildAction: Sendable, Equatable {
		case assets(AssetsView.Action)
	}
}

// MARK: - AccountDetails.Action.ViewAction
public extension AccountDetails.Action {
	enum ViewAction: Sendable, Equatable {
		case appeared
		case dismissAccountDetailsButtonTapped
		case displayAccountPreferencesButtonTapped
		case copyAddressButtonTapped
		case transferButtonTapped
		case pullToRefreshStarted
	}
}

// MARK: - AccountDetails.Action.InternalAction
public extension AccountDetails.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
	}
}

// MARK: - AccountDetails.Action.DelegateAction
public extension AccountDetails.Action {
	enum DelegateAction: Sendable, Equatable {
		case dismissAccountDetails
		case displayAccountPreferences(AccountAddress)
		case displayTransfer
		case refresh(AccountAddress)
	}
}
