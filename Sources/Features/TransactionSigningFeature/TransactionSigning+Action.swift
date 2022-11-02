import ComposableArchitecture
import EngineToolkit
import Foundation
import ProfileClient

// MARK: - TransactionSigning.Action
public extension TransactionSigning {
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case signTransaction
	}
}

// MARK: - TransactionSigning.Action.InternalAction
public extension TransactionSigning.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

// MARK: - TransactionSigning.Action.InternalAction.UserAction
public extension TransactionSigning.Action.InternalAction {
	enum UserAction: Equatable {
		case signTransactionResult(TaskResult<TransactionIntent.TXID>)
	}
}

// MARK: - TransactionSigning.Action.InternalAction.SystemAction
public extension TransactionSigning.Action.InternalAction {
	enum SystemAction: Equatable {
		case addressLookupFailed(NSError)
	}
}

// MARK: - TransactionSigning.Action.CoordinatingAction
public extension TransactionSigning.Action {
	enum CoordinatingAction: Equatable {
		case dismissView
	}
}
