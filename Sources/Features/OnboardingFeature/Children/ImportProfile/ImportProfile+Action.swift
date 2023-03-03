import FeaturePrelude

// MARK: - ImportProfile.Action
extension ImportProfile {
	public enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - ImportProfile.Action.ViewAction
extension ImportProfile.Action {
	public enum ViewAction: Sendable, Equatable {
		case goBack
		case dismissFileImporter
		case importProfileFileButtonTapped
		case profileImported(Result<URL, NSError>)
	}
}

// MARK: - ImportProfile.Action.InternalAction
extension ImportProfile.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - ImportProfile.Action.SystemAction
extension ImportProfile.Action {
	public enum SystemAction: Sendable, Equatable {}
}

// MARK: - ImportProfile.Action.DelegateAction
extension ImportProfile.Action {
	public enum DelegateAction: Sendable, Equatable {
		case goBack
		case imported
	}
}
