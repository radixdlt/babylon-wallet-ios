import Foundation

// MARK: - Home.VisitHub.Action
public extension Home.VisitHub {
	// MARK: Action
	enum Action: Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - Home.VisitHub.Action.ViewAction
public extension Home.VisitHub.Action {
	enum ViewAction: Equatable {
		case visitHubButtonTapped
	}
}

// MARK: - Home.VisitHub.Action.InternalAction
public extension Home.VisitHub.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
	}
}

// MARK: - Home.VisitHub.Action.DelegateAction
public extension Home.VisitHub.Action {
	enum DelegateAction: Equatable {
		case displayHub
	}
}
