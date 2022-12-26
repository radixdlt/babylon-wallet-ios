import Foundation

// MARK: - FungibleTokenDetails.Action
public extension FungibleTokenDetails {
	enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - FungibleTokenDetails.Action.ViewAction
public extension FungibleTokenDetails.Action {
	enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case copyAddressButtonTapped
	}
}

// MARK: - FungibleTokenDetails.Action.InternalAction
public extension FungibleTokenDetails.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - FungibleTokenDetails.Action.SystemAction
public extension FungibleTokenDetails.Action {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - FungibleTokenDetails.Action.DelegateAction
public extension FungibleTokenDetails.Action {
	enum DelegateAction: Sendable, Equatable {
		case closeButtonTapped
	}
}
