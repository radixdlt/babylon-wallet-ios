import ComposableArchitecture
import Foundation
import Profile

// MARK: - ImportProfile.Action
public extension ImportProfile {
	enum Action: Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - ImportProfile.Action.ViewAction
public extension ImportProfile.Action {
	enum ViewAction: Equatable {
		case goBack
		case dismissFileImporter
		case importProfileFileButtonTapped
		case profileImported(Result<URL, NSError>)
	}
}

// MARK: - ImportProfile.Action.InternalAction
public extension ImportProfile.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - ImportProfile.Action.SystemAction
public extension ImportProfile.Action {
	enum SystemAction: Equatable {}
}

// MARK: - ImportProfile.Action.DelegateAction
public extension ImportProfile.Action {
	enum DelegateAction: Equatable {
		case goBack
		case importedProfileSnapshot(ProfileSnapshot)
	}
}
