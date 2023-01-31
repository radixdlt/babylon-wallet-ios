import AssetsViewFeature
import FeaturePrelude

// MARK: - AccountDetails.Action
public extension AccountDetails {
	// MARK: Action
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		case view(ViewAction)
		case delegate(DelegateAction)
	}
}

// MARK: - AccountDetails.Action.ChildAction
public extension AccountDetails.Action {
	enum ChildAction: Sendable, Equatable {
		case assets(AssetsView.Action)
		case destination(PresentationActionOf<AccountDetails.Destinations>)
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

// MARK: - AccountDetails.Action.DelegateAction
public extension AccountDetails.Action {
	enum DelegateAction: Sendable, Equatable {
		case dismissAccountDetails
		case displayAccountPreferences(AccountAddress)
		case displayTransfer
		case refresh(AccountAddress)
	}
}
