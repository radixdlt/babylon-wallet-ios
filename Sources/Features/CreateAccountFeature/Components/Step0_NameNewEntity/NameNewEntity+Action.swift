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
//		case child(ChildAction)
		case delegate(DelegateAction)
	}
}

// MARK: - NameNewEntity.Action.ViewAction
public extension NameNewEntity.Action {
	enum ViewAction: Sendable, Equatable {
		case viewAppeared
		case closeButtonTapped
		case confirmNameButtonTapped
		case textFieldChanged(String)
		case textFieldFocused(NameNewEntity.State.Field?)
	}

//	enum ChildAction: Sendable, Equatable {
//		case gatherFactor(GatherFactor<GatherFactorPurposeDerivePublicKey>.Action)
//	}
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
//		case loadFactorSourcesResult(TaskResult<FactorSources>)
		case focusTextField(NameNewEntity.State.Field?)
//		case createdNewAccountResult(TaskResult<OnNetwork.Account>)
	}
}

// MARK: - NameNewEntity.Action.DelegateAction
public extension NameNewEntity.Action {
	enum DelegateAction: Sendable, Equatable {
		case dismiss
		case named(String)
//		case dismissCreateAccount
//		case createdNewAccount(account: OnNetwork.Account, isFirstAccount: Bool)
	}
}
