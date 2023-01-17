import EngineToolkitModels
import Prelude

// MARK: - EngineToolkit.Error
public extension EngineToolkit {
	enum Error: Sendable, LocalizedError, Equatable {
		/// We failed to call serialize the request, so we did not even get
		/// a chance to call the function in the Radix Engine Toolkit.
		case serializeRequestFailure(SerializeRequestFailure)

		/// We successfully serialized the request but failed to call the
		/// function in the Radix Engine Toolkit, or managed to call it but
		/// got no returned output.
		case callLibraryFunctionFailure(CallLibraryFunctionFailure)

		/// We successfully called the function in the Radix Engine Toolkit, but
		/// we failed to deserialize the returned output.
		case deserializeResponseFailure(DeserializeResponseFailure)
	}
}

// MARK: - EngineToolkit.Error.SerializeRequestFailure
public extension EngineToolkit.Error {
	/// We failed to call serialize the request, so we did not even get
	/// a chance to call the function in the Radix Engine Toolkit.
	enum SerializeRequestFailure: String, Sendable, LocalizedError, Equatable {
		case utf8DecodingFailed
		case jsonEncodeRequestFailed
	}
}

// MARK: - EngineToolkit.Error.CallLibraryFunctionFailure
public extension EngineToolkit.Error {
	/// We successfully serialized the request but failed to call the
	/// function in the Radix Engine Toolkit, or managed to call it but
	/// got no returned output.
	enum CallLibraryFunctionFailure: String, Sendable, LocalizedError, Equatable {
		/// We failed to call the function in the Radix Engine Toolkit since
		/// we failed to allocated memory for response.
		case allocatedMemoryForResponseFailedCouldNotUTF8EncodeCString

		/// We successfully called the function in the Radix Engine Toolkit, but
		/// we got no returned output back, which is expected and required.
		case noReturnedOutputFromLibraryFunction
	}
}

// MARK: - EngineToolkit.Error.DeserializeResponseFailure
public extension EngineToolkit.Error {
	/// We successfully called the function in the Radix Engine Toolkit, but
	/// we failed to deserialize the returned output.
	enum DeserializeResponseFailure: Sendable, LocalizedError, Equatable {
		/// Failed to even try deserializing the JSON response string into any decodable type.
		case beforeDecodingError(BeforeDecodingError)

		/// JSON decoding of response from library call was successful, but the
		/// actual call failed with an error response, a sematnic
		case errorResponse(ErrorResponse)

		/// Failed to decode the JSON response into expected resonse type and also failed to decode
		/// it into an `ErrorResponse`.
		case decodeResponseFailedAndCouldNotDecodeAsErrorResponseEither(responseType: String, decodingError: Swift.DecodingError)

		// When using JSONDecoder and casting thrown error to `Swift.DecodingError`
		/// (which always should work) but for some reason did not, maybe because we developers as
		/// part of a test used a subclass of JSONDecoder which throws a differnt kind of
		/// error than `Swift.DecodingError`
		case decodeResponseFailedAndCouldNotDecodeAsErrorResponseEitherNorAsSwiftDecodingError(responseType: String, nonSwiftDecodingError: String)
	}
}

// MARK: - EngineToolkit.Error.DeserializeResponseFailure.BeforeDecodingError
public extension EngineToolkit.Error.DeserializeResponseFailure {
	/// Failed to even try deserializing the JSON response string into any decodable type.
	enum BeforeDecodingError: String, Sendable, LocalizedError, Equatable {
		case failedToUTF8EncodeResponseJSONString
	}
}
