import ComposableArchitecture
import EngineToolkit
import Foundation
import ProfileClient

// MARK: - TransactionSigning.Action
public extension TransactionSigning {
	enum Action: Equatable {
		case view(ViewAction)
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - TransactionSigning.Action.ViewAction
public extension TransactionSigning.Action {
	enum ViewAction: Equatable {
		case signTransactionButtonTapped
		case errorAlertDismissButtonTapped
		case closeButtonTapped
	}
}

// MARK: - TransactionSigning.Action.InternalAction
public extension TransactionSigning.Action {
	enum InternalAction: Equatable {
		case signTransactionResult(TaskResult<TransactionIntent.TXID>)
		case addressLookupFailed(NSError)
	}
}

// MARK: - TransactionSigning.Action.DelegateAction
public extension TransactionSigning.Action {
	enum DelegateAction: Equatable {
		case dismissView
	}
}
