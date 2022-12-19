import Foundation

// MARK: - NonFungibleTokenDetails.Action
public extension NonFungibleTokenDetails {
	enum Action: Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - NonFungibleTokenDetails.Action.ViewAction
public extension NonFungibleTokenDetails.Action {
	enum ViewAction: Equatable {
		case closeButtonTapped
	}
}

// MARK: - NonFungibleTokenDetails.Action.InternalAction
public extension NonFungibleTokenDetails.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - NonFungibleTokenDetails.Action.SystemAction
public extension NonFungibleTokenDetails.Action {
	enum SystemAction: Equatable {}
}

// MARK: - NonFungibleTokenDetails.Action.DelegateAction
public extension NonFungibleTokenDetails.Action {
	enum DelegateAction: Equatable {
		case closeButtonTapped
	}
}
