import FeaturePrelude
import LocalAuthenticationClient

// MARK: - NameNewEntity.Action
extension NameNewEntity {
	// MARK: Action
	public enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - NameNewEntity.Action.ViewAction
extension NameNewEntity.Action {
	public enum ViewAction: Sendable, Equatable {
		case viewAppeared
		case confirmNameButtonTapped
		case textFieldChanged(String)
		case textFieldFocused(NameNewEntity.State.Field?)
	}
}

// MARK: - NameNewEntity.Action.InternalAction
extension NameNewEntity.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - NameNewEntity.Action.InternalAction.SystemAction
extension NameNewEntity.Action.InternalAction {
	public enum SystemAction: Sendable, Equatable {
		case focusTextField(NameNewEntity.State.Field?)
	}
}

// MARK: - NameNewEntity.Action.DelegateAction
extension NameNewEntity.Action {
	public enum DelegateAction: Sendable, Equatable {
		case named(NonEmpty<String>)
	}
}
