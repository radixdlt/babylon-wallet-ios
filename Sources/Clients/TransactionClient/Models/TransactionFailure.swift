
import ClientPrelude

// MARK: - TransactionFailure
public enum TransactionFailure: Sendable, LocalizedError, Equatable {
	case failedToPrepareTXReview(FailedToPreviewTXReview)
	case failedToPrepareForTXSigning(FailedToPrepareForTXSigning)
	case failedToCompileOrSign(CompileOrSignFailure)
	case failedToSubmit

	public var errorDescription: String? {
		switch self {
		case let .failedToPrepareTXReview(error):
			return error.localizedDescription
		case let .failedToPrepareForTXSigning(error):
			return error.localizedDescription
		case let .failedToCompileOrSign(error):
			return error.localizedDescription
		case .failedToSubmit:
			return "Failed to submit tx"
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
			case .failedToFindAccountWithEnoughFundsToLockFee:
				return (errorKind: .failedToFindAccountWithEnoughFundsToLockFee, message: error.errorDescription)
			case .failedToGetEpoch, .failedToLoadNotaryAndSigners, .failedToLoadNotaryPublicKey, .failedToLoadSignerPublicKeys, .failedToParseTXItIsProbablyInvalid:
				return (errorKind: .failedToPrepareTransaction, message: error.errorDescription)
			}

		case .failedToPrepareTXReview(.failedToRetrieveTXPreview),
		     .failedToPrepareTXReview(.failedToExtractTXReceiptBytes),
		     .failedToPrepareTXReview(.failedToGenerateTXReview),
		     .failedToPrepareTXReview(.failedToRetrieveTXReceipt):
			return (errorKind: .failedToPrepareTransaction, message: self.errorDescription)

		case let .failedToCompileOrSign(error):
			switch error {
			case .failedToCompileNotarizedTXIntent, .failedToCompileTXIntent, .failedToCompileSignedTXIntent, .failedToGenerateTXId, .failedToLoadFactorSourceForSigning:
				return (errorKind: .failedToCompileTransaction, message: error.errorDescription)
			case .failedToSignIntentWithAccountSigners, .failedToSignSignedCompiledIntentWithNotarySigner, .failedToConvertNotarySignature, .failedToConvertAccountSignatures:
				return (errorKind: .failedToSignTransaction, message: nil)
			}
		case .failedToSubmit:
			return (errorKind: .failedToSubmitTransaction, message: nil)

//		case let .failedToSubmit(error):
//			switch error {
//			case .failedToSubmitTX:
//				return (errorKind: .failedToSubmitTransaction, message: nil)
//			case let .invalidTXWasDuplicate(txID):
//				return (errorKind: .submittedTransactionWasDuplicate, message: "TXID: \(txID)")
//			}
//
//		case let .failedToPoll(error):
//			switch error {
//			case let .invalidTXWasSubmittedButNotSuccessful(txID, status: .rejected):
//				return (errorKind: .submittedTransactionHasRejectedTransactionStatus, message: "TXID: \(txID)")
//			case let .invalidTXWasSubmittedButNotSuccessful(txID, status: .failed):
//				return (errorKind: .submittedTransactionHasFailedTransactionStatus, message: "TXID: \(txID)")
//			case let .failedToPollTX(txID, _):
//				return (errorKind: .failedToPollSubmittedTransaction, message: "TXID: \(txID)")
//			case let .failedToGetTransactionStatus(txID, _):
//				return (errorKind: .failedToPollSubmittedTransaction, message: "TXID: \(txID)")
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

		public var errorDescription: String? {
			switch self {
			case let .failedSigning(error):
				return error.errorDescription
			case let .failedToRetrieveTXPreview(error):
				return "Failed to retrieve TX review from gateway: \(error.localizedDescription)"
			case let .failedToExtractTXReceiptBytes(error):
				return "Failed to extract TX review bytes: \(error.localizedDescription)"
			case let .failedToGenerateTXReview(error):
				return "ET failed to generate TX review: \(error.localizedDescription)"
			case let .failedToRetrieveTXReceipt(message):
				return "Failed to retrive TX receipt from gateway: \(message)"
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
		case failedToFindAccountWithEnoughFundsToLockFee

		public var errorDescription: String? {
			switch self {
			case .failedToParseTXItIsProbablyInvalid:
				return "Failed to parse transaction, it is probably invalid."
			case .failedToGetEpoch:
				return "Failed to get epoch"
			case .failedToLoadNotaryPublicKey:
				return "Failed to load notary public key"
			case .failedToLoadSignerPublicKeys:
				return "Failed to load signer public keys"
			case .failedToLoadNotaryAndSigners:
				return "Failed to load notary and signers"
			case .failedToFindAccountWithEnoughFundsToLockFee:
				return "Failed to find an account with enough funds to lock fee"
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
				return "Failed to load factor source for signing"
			case .failedToCompileTXIntent:
				return "Failed to compile transaction intent"
			case .failedToGenerateTXId:
				return "Failed to generate TXID"
			case .failedToCompileSignedTXIntent:
				return "Failed to compile signed transaction intent"
			case .failedToSignIntentWithAccountSigners:
				return "Failed to sign intent with signer(s) of account(s)."
			case .failedToSignSignedCompiledIntentWithNotarySigner:
				return "Failed to sign signed compiled intent with notary signer"
			case .failedToConvertAccountSignatures:
				return "Failed to convert account signatures"
			case .failedToConvertNotarySignature:
				return "Failed to convert notary signature"
			case .failedToCompileNotarizedTXIntent:
				return "Failed to compiler notarized transaction intent"
			}
		}
	}
}
