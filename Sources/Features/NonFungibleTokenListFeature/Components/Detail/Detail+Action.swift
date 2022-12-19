import Foundation

// MARK: - NonFungibleTokenList.Detail.Action
public extension NonFungibleTokenList.Detail {
	enum Action: Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - NonFungibleTokenList.Detail.Action.ViewAction
public extension NonFungibleTokenList.Detail.Action {
	enum ViewAction: Equatable {
		case closeButtonTapped
		case copyAddressButtonTapped(String)
	}
}

// MARK: - NonFungibleTokenList.Detail.Action.InternalAction
public extension NonFungibleTokenList.Detail.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - NonFungibleTokenList.Detail.Action.SystemAction
public extension NonFungibleTokenList.Detail.Action {
	enum SystemAction: Equatable {}
}

// MARK: - NonFungibleTokenList.Detail.Action.DelegateAction
public extension NonFungibleTokenList.Detail.Action {
	enum DelegateAction: Equatable {
		case closeButtonTapped
	}
}
