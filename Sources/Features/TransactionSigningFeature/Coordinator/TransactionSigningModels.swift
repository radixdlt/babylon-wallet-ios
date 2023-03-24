import EngineToolkitClient
import FeaturePrelude
import TransactionClient

extension EngineToolkit.Error {
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
