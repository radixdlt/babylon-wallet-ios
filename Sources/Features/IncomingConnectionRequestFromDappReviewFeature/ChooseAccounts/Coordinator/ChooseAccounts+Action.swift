import Collections
import Foundation
import NonEmpty
import Profile

// MARK: - ChooseAccounts.Action
public extension ChooseAccounts {
	enum Action: Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - ChooseAccounts.Action.ChildAction
public extension ChooseAccounts.Action {
	enum ChildAction: Equatable {
		case account(id: ChooseAccounts.Row.State.ID, action: ChooseAccounts.Row.Action)
	}
}

// MARK: - ChooseAccounts.Action.ViewAction
public extension ChooseAccounts.Action {
	enum ViewAction: Equatable {
		case continueButtonTapped
		case backButtonTapped
	}
}

// MARK: - ChooseAccounts.Action.InternalAction
public extension ChooseAccounts.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - ChooseAccounts.Action.InternalAction.SystemAction
public extension ChooseAccounts.Action.InternalAction {
	enum SystemAction: Equatable {}
}

// MARK: - ChooseAccounts.Action.DelegateAction
public extension ChooseAccounts.Action {
	enum DelegateAction: Equatable {
		case finishedChoosingAccounts(NonEmpty<OrderedSet<OnNetwork.Account>>)
		case dismissChooseAccounts
	}
}
