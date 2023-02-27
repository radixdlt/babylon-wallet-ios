import AssetsViewFeature
import FeaturePrelude

// MARK: - AccountDetails.Action
extension AccountDetails {
	// MARK: Action
	public enum Action: Sendable, Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - AccountDetails.Action.ChildAction
extension AccountDetails.Action {
	public enum ChildAction: Sendable, Equatable {
		case assets(AssetsView.Action)
		case destination(PresentationAction<AccountDetails.Destinations.Action>)
	}
}

// MARK: - AccountDetails.Action.ViewAction
extension AccountDetails.Action {
	public enum ViewAction: Sendable, Equatable {
		case appeared
		case backButtonTapped
		case preferencesButtonTapped
		case copyAddressButtonTapped
		case transferButtonTapped
		case pullToRefreshStarted
	}
}

// MARK: - AccountDetails.Action.InternalAction
extension AccountDetails.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
	}
}

// MARK: - AccountDetails.Action.DelegateAction
extension AccountDetails.Action {
	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case displayTransfer
		case refresh(AccountAddress)
	}
}
