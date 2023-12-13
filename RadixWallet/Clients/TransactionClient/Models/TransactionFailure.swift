// MARK: - TransactionFailure
public enum TransactionFailure: Sendable, LocalizedError, Equatable {
	case failedToPrepareTXReview(TransactionFailure.FailedToPreviewTXReview?)
	case failedToPrepareForTXSigning(FailedToPrepareForTXSigning)
	case failedToCompileOrSign(CompileOrSignFailure)
	case failedToSubmit

	public var errorDescription: String? {
		switch self {
		case let .failedToPrepareTXReview(error):
			error.map(\.localizedDescription) ?? L10n.Error.TransactionFailure.reviewFailure
		case let .failedToPrepareForTXSigning(error):
			error.localizedDescription
		case let .failedToCompileOrSign(error):
			error.localizedDescription
		case .failedToSubmit:
			"Failed to submit tx"
		}
	}
}

extension TransactionFailure {
	public var errorKindAndMessage: (errorKind: P2P.Dapp.Response.WalletInteractionFailureResponse.ErrorType, message: String?) {
		switch self {
		case let .failedToPrepareForTXSigning(error):
			switch error {
			case .failedToGetEpoch, .failedToLoadNotaryAndSigners, .failedToLoadNotaryPublicKey, .failedToLoadSignerPublicKeys, .failedToParseTXItIsProbablyInvalid:
				(errorKind: .failedToPrepareTransaction, message: error.errorDescription)
			}

		case .failedToPrepareTXReview:
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
		}
	}
}

// MARK: TransactionFailure.FailedToPreviewTXReview
extension TransactionFailure {
	public enum FailedToPreviewTXReview: Sendable, Error, Equatable {
		public enum RequestToGatewayFailed: Sendable, Error, Equatable {
			case gatewayPreviewRequestResponseIsGenericError(String)
			case gatewayPreviewRequestResponseIsOneOfRecevingAccountsDoesNotAllowDeposits
		}

		public enum AnalyzeResponseFromGatewayFailed: Sendable, Error, Equatable {
			case manifestWithReservedInstructions([ReservedInstruction])
			case other(String)
		}

		case failedBeforeRequestToGatewayWasMade(String)
		case requestToGatewayFailed(RequestToGatewayFailed)
		case analyzeResponseFromGatewayFailed(AnalyzeResponseFromGatewayFailed)
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
				"Failed to generate TXID"
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
