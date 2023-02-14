import FeaturePrelude

// MARK: - FungibleTokenDetails.Action
extension FungibleTokenDetails {
	public enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - FungibleTokenDetails.Action.ViewAction
extension FungibleTokenDetails.Action {
	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case copyAddressButtonTapped
	}
}

// MARK: - FungibleTokenDetails.Action.InternalAction
extension FungibleTokenDetails.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - FungibleTokenDetails.Action.SystemAction
extension FungibleTokenDetails.Action {
	public enum SystemAction: Sendable, Equatable {}
}

// MARK: - FungibleTokenDetails.Action.DelegateAction
extension FungibleTokenDetails.Action {
	public enum DelegateAction: Sendable, Equatable {
		case closeButtonTapped
	}
}
