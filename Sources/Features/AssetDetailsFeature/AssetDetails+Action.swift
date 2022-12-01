import Foundation

// MARK: - AssetDetails.Action
public extension AssetDetails {
	enum Action: Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - AssetDetails.Action.ViewAction
public extension AssetDetails.Action {
	enum ViewAction: Equatable {}
}

// MARK: - AssetDetails.Action.InternalAction
public extension AssetDetails.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - AssetDetails.Action.SystemAction
public extension AssetDetails.Action {
	enum SystemAction: Equatable {}
}

// MARK: - AssetDetails.Action.DelegateAction
public extension AssetDetails.Action {
	enum DelegateAction: Equatable {}
}
