
import Foundation

// MARK: - TransactionFailure
public enum TransactionFailure: Sendable, LocalizedError, Equatable {
	case failedToPrepareForTXSigning(FailedToPrepareForTXSigning)
	case failedToCompileOrSign(CompileOrSignFailure)
	case failedToSubmit(SubmitTXFailure)
}

// MARK: TransactionFailure.FailedToPrepareForTXSigning
public extension TransactionFailure {
	enum FailedToPrepareForTXSigning: Sendable, Swift.Error, Equatable {
		case failedToGetEpoch
		case failedToLoadNotaryPrivateKey
		case failedToLoadNotaryPublicKey
	}
}

// MARK: TransactionFailure.CompileOrSignFailure
public extension TransactionFailure {
	enum CompileOrSignFailure: Sendable, Swift.Error, Equatable {
		case failedToCompileTXIntent
		case failedToGenerateTXId
		case failedToCompileSignedTXIntent
		case failedToSign
		case failedToConvertSignature
		case failedToCompileNotarizedTXIntent
	}
}
