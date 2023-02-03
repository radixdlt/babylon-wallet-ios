import CreateEntityFeature
import FeaturePrelude

// MARK: - ChooseAccounts.Action
extension ChooseAccounts {
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - ChooseAccounts.Action.ChildAction
extension ChooseAccounts.Action {
	enum ChildAction: Sendable, Equatable {
		case account(id: ChooseAccounts.Row.State.ID, action: ChooseAccounts.Row.Action)
		case createAccountCoordinator(CreateAccountCoordinator.Action)
	}
}

// MARK: - ChooseAccounts.Action.ViewAction
extension ChooseAccounts.Action {
	enum ViewAction: Sendable, Equatable {
		case didAppear
		case continueButtonTapped
		case dismissButtonTapped
		case createAccountButtonTapped
	}
}

// MARK: - ChooseAccounts.Action.InternalAction
extension ChooseAccounts.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - ChooseAccounts.Action.InternalAction.SystemAction
extension ChooseAccounts.Action.InternalAction {
	enum SystemAction: Sendable, Equatable {
		case loadAccountsResult(TaskResult<NonEmpty<IdentifiedArrayOf<OnNetwork.Account>>>)
	}
}

// MARK: - ChooseAccounts.Action.DelegateAction
extension ChooseAccounts.Action {
	enum DelegateAction: Sendable, Equatable {
		case continueButtonTapped(IdentifiedArrayOf<OnNetwork.Account>)
		case dismissButtonTapped
	}
}
