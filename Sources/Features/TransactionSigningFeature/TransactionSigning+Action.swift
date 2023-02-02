import EngineToolkitClient
import FeaturePrelude
import enum TransactionClient.TransactionFailure
import enum TransactionClient.TransactionResult

// MARK: - TransactionSigning.Action
public extension TransactionSigning {
	enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - TransactionSigning.Action.ViewAction
public extension TransactionSigning.Action {
	enum ViewAction: Sendable, Equatable {
		case didAppear
		case signTransactionButtonTapped
		case dismissButtonTapped
	}
}

// MARK: - TransactionSigning.Action.InternalAction
public extension TransactionSigning.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case loadNetworkIDResult(TaskResult<NetworkID>, manifestWithFeeLock: TransactionManifest)
		case addLockFeeInstructionToManifestResult(TaskResult<TransactionManifest>)
		case signTransactionResult(TransactionResult)
	}
}

// MARK: - TransactionSigning.Action.DelegateAction
public extension TransactionSigning.Action {
	enum DelegateAction: Sendable, Equatable {
		case rejected
		case failed(ApproveTransactionFailure)
		case signedTXAndSubmittedToGateway(TransactionIntent.TXID)
	}
}

// MARK: - ApproveTransactionFailure
public enum ApproveTransactionFailure: Sendable, LocalizedError, Equatable {
	public enum PrepareTransactionFailure: Sendable, LocalizedError, Equatable {
		public static func == (lhs: Self, rhs: Self) -> Bool {
			lhs.errorDescription == rhs.errorDescription
		}

		case addTransactionFee(Swift.Error)
		case loadNetworkID(Swift.Error)
		public var errorDescription: String? {
			switch self {
			case let .addTransactionFee(error):
				let message = "Failed to add fee to transaction manifest"
				guard let engineToolkitError = error as? EngineToolkit.Error else {
					return message
				}
				return "\(message), engine toolkit: \(String(describing: engineToolkitError.errorDescription))"
			case let .loadNetworkID(error):
				return "Failed to load network ID, reason: \(String(describing: error))"
			}
		}
	}

	case prepareTransactionFailure(PrepareTransactionFailure)
	case transactionFailure(TransactionFailure)

	public var errorDescription: String? {
		switch self {
		case let .prepareTransactionFailure(error):
			return error.localizedDescription
		case let .transactionFailure(error):
			return error.localizedDescription
		}
	}
}

public extension EngineToolkit.Error {
	var errorDescription: String? {
		switch self {
		case let .callLibraryFunctionFailure(callLibraryFunctionFailure):
			switch callLibraryFunctionFailure {
			case .allocatedMemoryForResponseFailedCouldNotUTF8EncodeCString:
				return "Failed to allocate memory for response, could not utf8 encode string."
			case .noReturnedOutputFromLibraryFunction:
				return "No returned output from library function."
			}
		case let .deserializeResponseFailure(deserializeResponseFailure):
			switch deserializeResponseFailure {
			case let .beforeDecodingError(beforeDecodingError):
				switch beforeDecodingError {
				case .failedToUTF8EncodeResponseJSONString:
					return "Failed to utf8 encode response JSON string."
				}
			case let .decodeResponseFailedAndCouldNotDecodeAsErrorResponseEither(responseType, decodingError):
				return "Failed to decode response as \(responseType), underlying decoding error: \(decodingError)."
			case let .decodeResponseFailedAndCouldNotDecodeAsErrorResponseEitherNorAsSwiftDecodingError(responseType, nonSwiftDecodingError):
				return "Failed to decode response as \(responseType), underlying error: \(nonSwiftDecodingError)."
			case let .errorResponse(errorResponse):
				return "Internal toolkit error: \(String(describing: errorResponse))"
			}
		case let .serializeRequestFailure(serializeRequestFailure):
			switch serializeRequestFailure {
			case .jsonEncodeRequestFailed:
				return "JSON encode request failed."
			case .utf8DecodingFailed:
				return "UTF8 decoding failed"
			}
		}
	}
}
