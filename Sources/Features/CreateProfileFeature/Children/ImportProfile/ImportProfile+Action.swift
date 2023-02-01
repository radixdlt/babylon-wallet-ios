import FeaturePrelude
import ProfileClient

// MARK: - ImportProfile.Action
public extension ImportProfile {
	enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - ImportProfile.Action.ViewAction
public extension ImportProfile.Action {
	enum ViewAction: Sendable, Equatable {
		case goBack
		case dismissFileImporter
		case importProfileFileButtonTapped
		case profileImported(Result<URL, NSError>)
	}
}

// MARK: - ImportProfile.Action.InternalAction
public extension ImportProfile.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - ImportProfile.Action.SystemAction
public extension ImportProfile.Action {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - ImportProfile.Action.DelegateAction
public extension ImportProfile.Action {
	enum DelegateAction: Sendable, Equatable {
		case goBack
		case importedProfileSnapshot(ProfileSnapshot)
	}
}
