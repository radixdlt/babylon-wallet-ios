import EngineToolkitClient
import FeaturePrelude
import TransactionClient

// MARK: - ApproveTransactionFailure
public enum ApproveTransactionFailure: Sendable, LocalizedError, Equatable {
	public enum PrepareTransactionFailure: Sendable, LocalizedError, Equatable {
		public static func == (lhs: Self, rhs: Self) -> Bool {
			lhs.errorDescription == rhs.errorDescription
		}

		case addTransactionFee(Swift.Error)
		public var errorDescription: String? {
			switch self {
			case let .addTransactionFee(error):
				let message = "Failed to add fee to transaction manifest"
				guard let engineToolkitError = error as? EngineToolkit.Error else {
					return message
				}
				return "\(message), engine toolkit: \(String(describing: engineToolkitError.errorDescription))"
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

extension EngineToolkit.Error {
	public var errorDescription: String? {
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
