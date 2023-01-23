import Prelude

// MARK: - P2P.ToDapp.WalletInteractionFailureResponse
public extension P2P.ToDapp {
	struct WalletInteractionFailureResponse: Sendable, Hashable, Encodable {
		/// *MUST* match an ID from an incoming request from Dapp.
		public let interactionId: P2P.FromDapp.WalletInteraction.ID
		public let errorType: ErrorType
		public let message: String?

		public init(
			interactionId: P2P.FromDapp.WalletInteraction.ID,
			errorType: ErrorType,
			message: String?
		) {
			self.interactionId = interactionId
			self.errorType = errorType
			self.message = message
		}
	}
}

// MARK: - P2P.ToDapp.WalletInteractionFailureResponse.ErrorType
public extension P2P.ToDapp.WalletInteractionFailureResponse {
	enum ErrorType: String, Sendable, LocalizedError, Hashable, Encodable {
		case rejectedByUser
		case wrongNetwork
		case failedToPrepareTransaction
		case failedToCompileTransaction
		case failedToSignTransaction
		case failedToSubmitTransaction
		case failedToPollSubmittedTransaction
		case failedToFindAccountWithEnoughFundsToLockFee
		case submittedTransactionWasDuplicate
		case submittedTransactionHasFailedTransactionStatus
		case submittedTransactionHasRejectedTransactionStatus

		public var errorDescription: String? {
			switch self {
			case .rejectedByUser:
				return "Rejected by user"
			case .wrongNetwork:
				return "Wrong network"
			case .failedToCompileTransaction:
				return "Failed to compile transaction"
			case .failedToPrepareTransaction:
				return "Failed to prepare transaction for submission"
			case .failedToSignTransaction:
				return "Failed to sign transaction"
			case .failedToSubmitTransaction:
				return "Failed to submit transaction"
			case .failedToPollSubmittedTransaction:
				return "Failed to poll submitted transaction"
			case .failedToFindAccountWithEnoughFundsToLockFee:
				return "Failed to find an account with enough funds to lock fee"
			case .submittedTransactionWasDuplicate:
				return "Submitted transaction was a duplicate"
			case .submittedTransactionHasFailedTransactionStatus:
				return "Submitted transaction failed"
			case .submittedTransactionHasRejectedTransactionStatus:
				return "Submitted transaction was rejected"
			}
		}
	}
}
