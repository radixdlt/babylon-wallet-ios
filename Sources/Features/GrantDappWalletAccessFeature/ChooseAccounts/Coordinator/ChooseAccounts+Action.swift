import ComposableArchitecture
import CreateAccountFeature
import Prelude
import Profile
import SharedModels

// MARK: - ChooseAccounts.Action
public extension ChooseAccounts {
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - ChooseAccounts.Action.ChildAction
public extension ChooseAccounts.Action {
	enum ChildAction: Sendable, Equatable {
		case account(id: ChooseAccounts.Row.State.ID, action: ChooseAccounts.Row.Action)
		case createAccount(CreateAccount.Action)
	}
}

// MARK: - ChooseAccounts.Action.ViewAction
public extension ChooseAccounts.Action {
	enum ViewAction: Sendable, Equatable {
		case didAppear
		case continueButtonTapped
		case dismissButtonTapped
		case createAccountButtonTapped
	}
}

// MARK: - ChooseAccounts.Action.InternalAction
public extension ChooseAccounts.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - ChooseAccounts.Action.InternalAction.SystemAction
public extension ChooseAccounts.Action.InternalAction {
	enum SystemAction: Sendable, Equatable {
		case loadAccountsResult(TaskResult<NonEmpty<OrderedSet<OnNetwork.Account>>>)
		case createAccount(numberOfExistingAccounts: Int)
	}
}

// MARK: - ChooseAccounts.Action.DelegateAction
public extension ChooseAccounts.Action {
	enum DelegateAction: Sendable, Equatable {
		case finishedChoosingAccounts(NonEmpty<OrderedSet<OnNetwork.Account>>, P2P.OneTimeAccountAddressesRequestToHandle)
		case dismissChooseAccounts(P2P.OneTimeAccountAddressesRequestToHandle)
	}
}
