import Prelude

// MARK: - P2P.ToDapp.Response.Failure.Kind.Error
public extension P2P.ToDapp.Response.Failure.Kind {
	enum Error: String, Sendable, LocalizedError, Hashable {
		case wrongNetwork
		case failedToPrepareTransaction
		case failedToCompileTransaction
		case failedToSignTransaction
		case failedToSubmitTransaction
		case failedToPollSubmittedTransaction
		case submittedTransactionWasDuplicate
		case submittedTransactionHasFailedTransactionStatus
		case submittedTransactionHasRejectedTransactionStatus

		public var errorDescription: String? {
			switch self {
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
