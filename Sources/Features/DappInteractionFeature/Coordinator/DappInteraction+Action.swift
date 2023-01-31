import FeaturePrelude

// MARK: - DappInteraction.Action
public extension DappInteraction {
	enum Action: Sendable, Equatable {
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

public extension DappInteraction.Action {
	static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - DappInteraction.Action.ViewAction
public extension DappInteraction.Action {
	enum ViewAction: Sendable, Equatable {
		case appeared
	}
}

// MARK: - DappInteraction.Action.InternalAction
public extension DappInteraction.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - DappInteraction.Action.SystemAction
public extension DappInteraction.Action {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - DappInteraction.Action.DelegateAction
public extension DappInteraction.Action {
	enum DelegateAction: Sendable, Equatable {}
}
