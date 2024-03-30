// MARK: - TransactionFailure
public enum TransactionFailure: Sendable, LocalizedError, Equatable {
	case failedToPrepareTXReview(FailedToPreviewTXReview)
	case failedToPrepareForTXSigning(FailedToPrepareForTXSigning)
	case failedToCompileOrSign(CompileOrSignFailure)
	case failedToSubmit

	public var errorDescription: String? {
		switch self {
		case let .failedToPrepareTXReview(error):
			error.localizedDescription
		case let .failedToPrepareForTXSigning(error):
			error.localizedDescription
		case let .failedToCompileOrSign(error):
			error.localizedDescription
		case .failedToSubmit:
			"Failed to submit tx"
//		case let .failedToSubmit(error):
//			return error.localizedDescription
//		case let .failedToPoll(error):
//			return error.localizedDescription
		}
	}
}

extension TransactionFailure {
	public var errorKindAndMessage: (errorKind: P2P.Dapp.Response.WalletInteractionFailureResponse.ErrorType, message: String?) {
		switch self {
		case let .failedToPrepareForTXSigning(error), let .failedToPrepareTXReview(.failedSigning(error)):
			switch error {
			case .failedToGetEpoch, .failedToLoadNotaryAndSigners, .failedToLoadNotaryPublicKey, .failedToLoadSignerPublicKeys, .failedToParseTXItIsProbablyInvalid:
				(errorKind: .failedToPrepareTransaction, message: error.errorDescription)
			}

		case .failedToPrepareTXReview(.failedToRetrieveTXPreview),
		     .failedToPrepareTXReview(.failedToExtractTXReceiptBytes),
		     .failedToPrepareTXReview(.failedToGenerateTXReview),
		     .failedToPrepareTXReview(.failedToRetrieveTXReceipt),
		     .failedToPrepareTXReview(.manifestWithReservedInstructions),
		     .failedToPrepareTXReview(.oneOfRecevingAccountsDoesNotAllowDeposits):
			(errorKind: .failedToPrepareTransaction, message: self.errorDescription)

		case let .failedToCompileOrSign(error):
			switch error {
			case .failedToCompileNotarizedTXIntent, .failedToCompileTXIntent, .failedToCompileSignedTXIntent, .failedToGenerateTXId, .failedToLoadFactorSourceForSigning:
				(errorKind: .failedToCompileTransaction, message: error.errorDescription)
			case .failedToSignIntentWithAccountSigners, .failedToSignSignedCompiledIntentWithNotarySigner, .failedToConvertNotarySignature, .failedToConvertAccountSignatures:
				(errorKind: .failedToSignTransaction, message: nil)
			}
		case .failedToSubmit:
			(errorKind: .failedToSubmitTransaction, message: nil)

//		case let .failedToSubmit(error):
//			switch error {
//			case .failedToSubmitTX:
//				return (errorKind: .failedToSubmitTransaction, message: nil)
//			case let .invalidTXWasDuplicate(txID):
//				return (errorKind: .submittedTransactionWasDuplicate, message: "IntentHash: \(txID)")
//			}
//
//		case let .failedToPoll(error):
//			switch error {
//			case let .invalidTXWasSubmittedButNotSuccessful(txID, status: .rejected):
//				return (errorKind: .submittedTransactionHasRejectedTransactionStatus, message: "IntentHash: \(txID)")
//			case let .invalidTXWasSubmittedButNotSuccessful(txID, status: .failed):
//				return (errorKind: .submittedTransactionHasFailedTransactionStatus, message: "IntentHash: \(txID)")
//			case let .failedToPollTX(txID, _):
//				return (errorKind: .failedToPollSubmittedTransaction, message: "IntentHash: \(txID)")
//			case let .failedToGetTransactionStatus(txID, _):
//				return (errorKind: .failedToPollSubmittedTransaction, message: "IntentHash: \(txID)")
//			}
		}
	}
}

// MARK: TransactionFailure.FailedToPreviewTXReview
extension TransactionFailure {
	public enum FailedToPreviewTXReview: Sendable, LocalizedError, Equatable {
		case failedSigning(FailedToPrepareForTXSigning)
		case failedToRetrieveTXPreview(Error)
		case failedToRetrieveTXReceipt(String)
		case failedToExtractTXReceiptBytes(Error)
		case failedToGenerateTXReview(Error)
		case manifestWithReservedInstructions([ReservedInstruction])
		case oneOfRecevingAccountsDoesNotAllowDeposits

		public var errorDescription: String? {
			switch self {
			case let .failedSigning(error):
				error.errorDescription
			case let .failedToRetrieveTXPreview(error):
				"Failed to retrieve TX review from gateway: \(error.localizedDescription)"
			case let .failedToExtractTXReceiptBytes(error):
				"Failed to extract TX review bytes: \(error.localizedDescription)"
			case let .failedToGenerateTXReview(error):
				"ET failed to generate TX review: \(error.localizedDescription)"
			case let .failedToRetrieveTXReceipt(message):
				"Failed to retrive TX receipt from gateway: \(message)"
			case .manifestWithReservedInstructions:
				"Transaction Manifest contains forbidden instructions"
			case .oneOfRecevingAccountsDoesNotAllowDeposits:
				"One of the receiving accounts does not allow Third-Party deposits"
			}
		}
	}
}

// MARK: TransactionFailure.FailedToPrepareForTXSigning
extension TransactionFailure {
	public enum FailedToPrepareForTXSigning: Sendable, LocalizedError, Equatable {
		case failedToParseTXItIsProbablyInvalid
		case failedToGetEpoch
		case failedToLoadNotaryAndSigners
		case failedToLoadNotaryPublicKey
		case failedToLoadSignerPublicKeys

		public var errorDescription: String? {
			switch self {
			case .failedToParseTXItIsProbablyInvalid:
				"Failed to parse transaction, it is probably invalid."
			case .failedToGetEpoch:
				"Failed to get epoch"
			case .failedToLoadNotaryPublicKey:
				"Failed to load notary public key"
			case .failedToLoadSignerPublicKeys:
				"Failed to load signer public keys"
			case .failedToLoadNotaryAndSigners:
				"Failed to load notary and signers"
			}
		}
	}
}

// MARK: TransactionFailure.CompileOrSignFailure
extension TransactionFailure {
	public enum CompileOrSignFailure: Sendable, LocalizedError, Equatable {
		case failedToLoadFactorSourceForSigning
		case failedToCompileTXIntent
		case failedToGenerateTXId
		case failedToCompileSignedTXIntent
		case failedToSignIntentWithAccountSigners
		case failedToSignSignedCompiledIntentWithNotarySigner
		case failedToConvertAccountSignatures
		case failedToConvertNotarySignature
		case failedToCompileNotarizedTXIntent

		public var errorDescription: String? {
			switch self {
			case .failedToLoadFactorSourceForSigning:
				"Failed to load factor source for signing"
			case .failedToCompileTXIntent:
				"Failed to compile transaction intent"
			case .failedToGenerateTXId:
				"Failed to generate IntentHash"
			case .failedToCompileSignedTXIntent:
				"Failed to compile signed transaction intent"
			case .failedToSignIntentWithAccountSigners:
				"Failed to sign intent with signer(s) of account(s)."
			case .failedToSignSignedCompiledIntentWithNotarySigner:
				"Failed to sign signed compiled intent with notary signer"
			case .failedToConvertAccountSignatures:
				"Failed to convert account signatures"
			case .failedToConvertNotarySignature:
				"Failed to convert notary signature"
			case .failedToCompileNotarizedTXIntent:
				"Failed to compiler notarized transaction intent"
			}
		}
	}
}
