import ComposableArchitecture
import EngineToolkit
import Foundation
import ProfileClient
import SharedModels
import enum TransactionClient.TransactionResult

// MARK: - TransactionSigning.Action
public extension TransactionSigning {
	enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - TransactionSigning.Action.ViewAction
public extension TransactionSigning.Action {
	enum ViewAction: Sendable, Equatable {
		case didAppear
		case signTransactionButtonTapped
		case closeButtonTapped
	}
}

// MARK: - TransactionSigning.Action.InternalAction
public extension TransactionSigning.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case loadNetworkIDResult(TaskResult<NetworkID>, manifestWithFeeLock: TransactionManifest)
		case addLockFeeInstructionToManifestResult(TaskResult<TransactionManifest>)
		case signTransactionResult(TransactionResult)
	}
}

// MARK: - TransactionSigning.Action.DelegateAction
public extension TransactionSigning.Action {
	enum DelegateAction: Sendable, Equatable {
		case dismissed(P2P.SignTransactionRequestToHandle)

		case signedTXAndSubmittedToGateway(
			TransactionIntent.TXID,
			request: P2P.SignTransactionRequestToHandle
		)
	}
}
