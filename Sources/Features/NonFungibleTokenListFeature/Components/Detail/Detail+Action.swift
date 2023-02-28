import FeaturePrelude

// MARK: - NonFungibleTokenList.Detail.Action
extension NonFungibleTokenList.Detail {
	public enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - NonFungibleTokenList.Detail.Action.ViewAction
extension NonFungibleTokenList.Detail.Action {
	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case copyAddressButtonTapped(String)
	}
}

// MARK: - NonFungibleTokenList.Detail.Action.InternalAction
extension NonFungibleTokenList.Detail.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - NonFungibleTokenList.Detail.Action.SystemAction
extension NonFungibleTokenList.Detail.Action {
	public enum SystemAction: Sendable, Equatable {}
}

// MARK: - NonFungibleTokenList.Detail.Action.DelegateAction
extension NonFungibleTokenList.Detail.Action {
	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}
}
