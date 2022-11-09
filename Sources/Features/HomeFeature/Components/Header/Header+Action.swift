import Foundation

// MARK: - Home.Header.Action
public extension Home.Header {
	// MARK: Action
	enum Action: Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - Home.Header.Action.ViewAction
public extension Home.Header.Action {
	enum ViewAction: Equatable {
		case settingsButtonTapped
	}
}

// MARK: - Home.Header.Action.InternalAction
public extension Home.Header.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
	}
}

// MARK: - Home.Header.Action.DelegateAction
public extension Home.Header.Action {
	enum DelegateAction: Equatable {
		case displaySettings
	}
}
