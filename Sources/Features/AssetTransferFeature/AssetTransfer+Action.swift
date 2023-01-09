import Asset

// MARK: - AssetTransfer.Action
public extension AssetTransfer {
	// MARK: Action
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - AssetTransfer.Action.ChildAction
public extension AssetTransfer.Action {
	enum ChildAction: Sendable, Equatable {}
}

// MARK: - AssetTransfer.Action.ViewAction
public extension AssetTransfer.Action {
	enum ViewAction: Sendable, Equatable {}
}

// MARK: - AssetTransfer.Action.InternalAction
public extension AssetTransfer.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - AssetTransfer.Action.InternalAction.SystemAction
public extension AssetTransfer.Action.InternalAction {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - AssetTransfer.Action.DelegateAction
public extension AssetTransfer.Action {
	enum DelegateAction: Sendable, Equatable {}
}
