import FeaturePrelude

// MARK: - Home.Header.Action
extension Home.Header {
	// MARK: Action
	public enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - Home.Header.Action.ViewAction
extension Home.Header.Action {
	public enum ViewAction: Sendable, Equatable {
		case settingsButtonTapped
	}
}

// MARK: - Home.Header.Action.InternalAction
extension Home.Header.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
	}
}

// MARK: - Home.Header.Action.DelegateAction
extension Home.Header.Action {
	public enum DelegateAction: Sendable, Equatable {
		case displaySettings
	}
}
