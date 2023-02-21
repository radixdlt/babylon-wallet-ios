
import ClientPrelude

// MARK: - TransactionFailure
public enum TransactionFailure: Sendable, LocalizedError, Equatable {
	case failedToPrepareForTXSigning(FailedToPrepareForTXSigning)
	case failedToCompileOrSign(CompileOrSignFailure)
	case failedToSubmit(SubmitTXFailure)

	public var errorDescription: String? {
		switch self {
		case let .failedToPrepareForTXSigning(error):
			return error.localizedDescription
		case let .failedToCompileOrSign(error):
			return error.localizedDescription
		case let .failedToSubmit(error):
			return error.localizedDescription
		}
	}
}

extension TransactionFailure {
	public var errorKindAndMessage: (errorKind: P2P.ToDapp.WalletInteractionFailureResponse.ErrorType, message: String?) {
		switch self {
		case let .failedToPrepareForTXSigning(error):
			switch error {
			case .failedToFindAccountWithEnoughFundsToLockFee:
				return (errorKind: .failedToFindAccountWithEnoughFundsToLockFee, message: error.errorDescription)
			case .failedToGetEpoch, .failedToLoadNotaryAndSigners, .failedToLoadNotaryPublicKey, .failedToParseTXItIsProbablyInvalid:
				return (errorKind: .failedToPrepareTransaction, message: error.errorDescription)
			}

		case let .failedToCompileOrSign(error):
			switch error {
			case .failedToCompileNotarizedTXIntent, .failedToCompileTXIntent, .failedToCompileSignedTXIntent, .failedToGenerateTXId:
				return (errorKind: .failedToCompileTransaction, message: nil)
			case .failedToSignIntentWithAccountSigners, .failedToSignSignedCompiledIntentWithNotarySigner, .failedToConvertNotarySignature, .failedToConvertAccountSignatures:
				return (errorKind: .failedToSignTransaction, message: nil)
			}

		case let .failedToSubmit(error):
			switch error {
			case .failedToSubmitTX:
				return (errorKind: .failedToSubmitTransaction, message: nil)
			case let .invalidTXWasSubmittedButNotSuccessful(txID, status: .rejected):
				return (errorKind: .submittedTransactionHasRejectedTransactionStatus, message: "TXID: \(txID)")
			case let .invalidTXWasSubmittedButNotSuccessful(txID, status: .failed):
				return (errorKind: .submittedTransactionHasFailedTransactionStatus, message: "TXID: \(txID)")
			case let .failedToPollTX(txID, _):
				return (errorKind: .failedToPollSubmittedTransaction, message: "TXID: \(txID)")
			case let .invalidTXWasDuplicate(txID):
				return (errorKind: .submittedTransactionWasDuplicate, message: "TXID: \(txID)")
			case let .failedToGetTransactionStatus(txID, _):
				return (errorKind: .failedToPollSubmittedTransaction, message: "TXID: \(txID)")
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
		case failedToFindAccountWithEnoughFundsToLockFee

		public var errorDescription: String? {
			switch self {
			case .failedToParseTXItIsProbablyInvalid:
				return "Failed to parse transaction, it is probably invalid."
			case .failedToGetEpoch:
				return "Failed to get epoch"
			case .failedToLoadNotaryPublicKey:
				return "Failed to load notary public key"
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
