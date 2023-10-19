// MARK: - P2P.Dapp.Response.WalletInteractionFailureResponse
extension P2P.Dapp.Response {
	public struct WalletInteractionFailureResponse: Sendable, Hashable, Encodable {
		private enum CodingKeys: String, CodingKey {
			case interactionId
			case errorType = "error"
			case message
		}

		/// *MUST* match an ID from an incoming request from Dapp.
		public let interactionId: P2P.Dapp.Request.ID
		public let errorType: ErrorType
		public let message: String?

		public init(
			interactionId: P2P.Dapp.Request.ID,
			errorType: ErrorType,
			message: String?
		) {
			self.interactionId = interactionId
			self.errorType = errorType
			self.message = message
		}
	}
}

// MARK: - P2P.Dapp.Response.WalletInteractionFailureResponse.ErrorType
extension P2P.Dapp.Response.WalletInteractionFailureResponse {
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
		case invalidRequest
		case incompatibleVersion
		case failedToSignAuthChallenge

		public var errorDescription: String? {
			switch self {
			case .rejectedByUser:
				"Rejected by user"
			case .wrongNetwork:
				"Wrong network"
			case .failedToCompileTransaction:
				"Failed to compile transaction"
			case .failedToPrepareTransaction:
				"Failed to prepare transaction for submission"
			case .failedToSignTransaction:
				"Failed to sign transaction"
			case .failedToSubmitTransaction:
				"Failed to submit transaction"
			case .failedToPollSubmittedTransaction:
				"Failed to poll submitted transaction"
			case .failedToFindAccountWithEnoughFundsToLockFee:
				"Failed to find an account with enough funds to lock fee"
			case .submittedTransactionWasDuplicate:
				"Submitted transaction was a duplicate"
			case .submittedTransactionHasFailedTransactionStatus:
				"Submitted transaction failed"
			case .submittedTransactionHasRejectedTransactionStatus:
				"Submitted transaction was rejected"
			case .wrongAccountType:
				"Expected to find dapp definition account type"
			case .unknownWebsite:
				"Origin does not match any related website"
			case .invalidOriginURL:
				"Invalid origin URL"
			case .radixJsonNotFound:
				"radix.json file is missing"
			case .radixJsonUnknownFileFormat:
				"radix.json file format mismatch "
			case .unknownDappDefinitionAddress:
				"dApp definition address does not match any well known definition address"
			case .invalidPersona:
				"Invalid persona specified by dApp"
			case .invalidRequest:
				"Invalid request"
			case .failedToSignAuthChallenge:
				"Failed to sign auth challenge"
			case .incompatibleVersion:
				"Incompatible versions"
			}
		}
	}
}
