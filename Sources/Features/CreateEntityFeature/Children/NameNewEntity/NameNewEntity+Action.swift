import FeaturePrelude
import GatherFactorsFeature
import LocalAuthenticationClient
import ProfileClient

// MARK: - NameNewEntity.Action
public extension NameNewEntity {
	// MARK: Action
	enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - NameNewEntity.Action.ViewAction
public extension NameNewEntity.Action {
	enum ViewAction: Sendable, Equatable {
		case viewAppeared
		case confirmNameButtonTapped
		case textFieldChanged(String)
		case textFieldFocused(NameNewEntity.State.Field?)
	}
}

// MARK: - NameNewEntity.Action.InternalAction
public extension NameNewEntity.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - NameNewEntity.Action.InternalAction.SystemAction
public extension NameNewEntity.Action.InternalAction {
	enum SystemAction: Sendable, Equatable {
		case focusTextField(NameNewEntity.State.Field?)
	}
}

// MARK: - NameNewEntity.Action.DelegateAction
public extension NameNewEntity.Action {
	enum DelegateAction: Sendable, Equatable {
		case dismiss
		case named(NonEmpty<String>)
	}
}
