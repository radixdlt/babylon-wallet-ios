import FeaturePrelude

// MARK: - DappInteraction.Action
public extension DappInteraction {
	enum Action: Sendable, Equatable {
		case view(ViewAction)
		case `internal`(InternalAction)
		case child(ChildAction)
		case delegate(DelegateAction)
	}
}

// MARK: - DappInteraction.Action.ViewAction
public extension DappInteraction.Action {
	enum ViewAction: Sendable, Equatable {
		case appeared
	}
}

// MARK: - DappInteraction.Action.InternalAction
public extension DappInteraction.Action {
	enum InternalAction: Sendable, Equatable {}
}

// MARK: - DappInteraction.Action.ChildAction
public extension DappInteraction.Action {
	enum ChildAction: Sendable, Equatable {
		case navigation(NavigationActionOf<DappInteraction.Destinations>)
	}
}

// MARK: - DappInteraction.Action.DelegateAction
public extension DappInteraction.Action {
	enum DelegateAction: Sendable, Equatable {}
}
