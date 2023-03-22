import Prelude

// MARK: - P2P.ToDapp.WalletInteractionFailureResponse
extension P2P.ToDapp {
	public struct WalletInteractionFailureResponse: Sendable, Hashable, Encodable {
		private enum CodingKeys: String, CodingKey {
			case interactionId
			case errorType = "error"
			case message
		}

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
extension P2P.ToDapp.WalletInteractionFailureResponse {
	// TODO: ask if we should do associated values here for `message` construction,
	// in which case we'll need to declare discriminators
	public enum ErrorType: String, Sendable, LocalizedError, Hashable, Encodable {
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
		case wrongAccountType
		case unknownWebsite
		case invalidOriginURL
		case radixJsonNotFound
		case radixJsonUnknownFileFormat
		case unknownDappDefinitionAddress
		case invalidPersona

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
			case .wrongAccountType:
				return "Expected to find dapp definition account type"
			case .unknownWebsite:
				return "Origin does not match any related website"
			case .invalidOriginURL:
				return "Invalid origin URL"
			case .radixJsonNotFound:
				return "radix.json file is missing"
			case .radixJsonUnknownFileFormat:
				return "radix.json file format mismatch "
			case .unknownDappDefinitionAddress:
				return "dApp definition address does not match any well known definition address"
			case .invalidPersona:
				return "Invalid persona specified by dApp"
			}
		}
	}
}
