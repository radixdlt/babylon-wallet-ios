import FeaturePrelude
import GatherFactorsFeature
import LocalAuthenticationClient
import ProfileClient

// MARK: - CreateAccount.Action
public extension CreateAccount {
	// MARK: Action
	enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case child(ChildAction)
		case delegate(DelegateAction)
	}
}

// MARK: - CreateAccount.Action.ViewAction
public extension CreateAccount.Action {
	enum ViewAction: Sendable, Equatable {
		case viewAppeared
		case closeButtonTapped
		case createAccountButtonTapped
		case textFieldChanged(String)
		case textFieldFocused(CreateAccount.State.Field?)
	}

	enum ChildAction: Sendable, Equatable {
		case gatherFactors(GatherFactors.Action)
	}
}

// MARK: - CreateAccount.Action.InternalAction
public extension CreateAccount.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - CreateAccount.Action.InternalAction.SystemAction
public extension CreateAccount.Action.InternalAction {
	enum SystemAction: Sendable, Equatable {
		case loadFactorSourcesResult(TaskResult<FactorSources>)
		case focusTextField(CreateAccount.State.Field?)
		case createdNewAccountResult(TaskResult<OnNetwork.Account>)
	}
}

// MARK: - CreateAccount.Action.DelegateAction
public extension CreateAccount.Action {
	enum DelegateAction: Sendable, Equatable {
		case dismissCreateAccount
		case createdNewAccount(account: OnNetwork.Account, isFirstAccount: Bool)
	}
}
