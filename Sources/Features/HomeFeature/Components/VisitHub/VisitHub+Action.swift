import FeaturePrelude

// MARK: - Home.VisitHub.Action
extension Home.VisitHub {
	// MARK: Action
	public enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - Home.VisitHub.Action.ViewAction
extension Home.VisitHub.Action {
	public enum ViewAction: Sendable, Equatable {
		case visitHubButtonTapped
	}
}

// MARK: - Home.VisitHub.Action.InternalAction
extension Home.VisitHub.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
	}
}

// MARK: - Home.VisitHub.Action.DelegateAction
extension Home.VisitHub.Action {
	public enum DelegateAction: Sendable, Equatable {
		case displayHub
	}
}
