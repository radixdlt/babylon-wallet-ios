
import Foundation

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

// MARK: TransactionFailure.FailedToPrepareForTXSigning
public extension TransactionFailure {
	enum FailedToPrepareForTXSigning: Sendable, LocalizedError, Equatable {
		case failedToGetEpoch
		case failedToLoadNotaryAndSigners
		case failedToLoadNotaryPublicKey

		public var errorDescription: String? {
			switch self {
			case .failedToGetEpoch:
				return "Failed to get epoch"
			case .failedToLoadNotaryPublicKey:
				return "Failed to load notary public key"
			case .failedToLoadNotaryAndSigners:
				return "Failed to load notary and signers"
			}
		}
	}
}

// MARK: TransactionFailure.CompileOrSignFailure
public extension TransactionFailure {
	enum CompileOrSignFailure: Sendable, LocalizedError, Equatable {
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
