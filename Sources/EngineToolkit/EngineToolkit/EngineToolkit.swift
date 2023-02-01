import EngineToolkitModels
import Prelude
@_implementationOnly import RadixEngineToolkit

typealias UnderlyingPointerType = CChar
typealias MutableToolkitPointer = UnsafeMutablePointer<UnderlyingPointerType>
typealias ImmutableToolkitPointer = UnsafePointer<UnderlyingPointerType>

// MARK: - EngineToolkit
/// A type provides a high level functions and method for the
/// interaction with the transaction library and abstracting away
/// the low level memory allocation, serialization, and other low level concepts.
public struct EngineToolkit {
	internal static var _debugPrint = false

	private let jsonEncoder: JSONEncoder
	private let jsonDecoder: JSONDecoder

	private let jsonStringFromJSONData: JSONStringFromJSONData
	private let jsonDataFromJSONString: JSONDataFromJSONString

	public init() {
		self.init(
			jsonEncoder: JSONEncoder(),
			jsonDecoder: JSONDecoder()
		)
	}

	internal init(
		jsonEncoder: JSONEncoder = .init(),
		jsonDecoder: JSONDecoder = .init(),
		jsonStringFromJSONData: @escaping JSONStringFromJSONData = { String(data: $0, encoding: .utf8) },
		jsonDataFromJSONString: @escaping JSONDataFromJSONString = { $0.data(using: .utf8) }
	) {
		self.jsonEncoder = jsonEncoder
		self.jsonDecoder = jsonDecoder
		self.jsonStringFromJSONData = jsonStringFromJSONData
		self.jsonDataFromJSONString = jsonDataFromJSONString
	}
}

internal extension EngineToolkit {
	typealias JSONStringFromJSONData = @Sendable (Data) -> String?
	typealias CCharsFromJSONString = @Sendable (String) -> [CChar]?
	typealias JSONDataFromJSONString = @Sendable (String) -> Data?
}

// MARK: Public

public extension EngineToolkit {
	/// Obtains information on the current transaction library used.
	///
	/// This function is used to get information on the transaction library such as the package version. You may
	/// think of this information request as the "Hello World" example of the transaction library where, this is
	/// typically the first request type to be implemented in any implementation of the transaction library, if this
	/// request works then you can be assured that all of the other lower level operations work as well.
	func information() -> Result<InformationResponse, Error> {
		callLibraryFunction(
			request: InformationRequest(),
			function: RadixEngineToolkit.information
		)
	}

	func convertManifest(
		request: ConvertManifestRequest
	) -> Result<ConvertManifestResponse, Error> {
		callLibraryFunction(
			request: request,
			function: convert_manifest
		)
	}

	func compileTransactionIntentRequest(
		request: CompileTransactionIntentRequest
	) -> Result<CompileTransactionIntentResponse, Error> {
		callLibraryFunction(
			request: request,
			function: compile_transaction_intent
		)
	}

	func decompileTransactionIntentRequest(
		request: DecompileTransactionIntentRequest
	) -> Result<DecompileTransactionIntentResponse, Error> {
		callLibraryFunction(
			request: request,
			function: decompile_transaction_intent
		)
	}

	func compileSignedTransactionIntentRequest(
		request: CompileSignedTransactionIntentRequest
	) -> Result<CompileSignedTransactionIntentResponse, Error> {
		callLibraryFunction(
			request: request,
			function: compile_signed_transaction_intent
		)
	}

	func decompileSignedTransactionIntentRequest(
		request: DecompileSignedTransactionIntentRequest
	) -> Result<DecompileSignedTransactionIntentResponse, Error> {
		callLibraryFunction(
			request: request,
			function: decompile_signed_transaction_intent
		)
	}

	func compileNotarizedTransactionIntentRequest(
		request: CompileNotarizedTransactionIntentRequest
	) -> Result<CompileNotarizedTransactionIntentResponse, Error> {
		callLibraryFunction(
			request: request,
			function: compile_notarized_transaction
		)
	}

	func decompileNotarizedTransactionIntentRequest(
		request: DecompileNotarizedTransactionIntentRequest
	) -> Result<DecompileNotarizedTransactionIntentResponse, Error> {
		callLibraryFunction(
			request: request,
			function: decompile_notarized_transaction
		)
	}

	func decompileUnknownTransactionIntentRequest(
		request: DecompileUnknownTransactionIntentRequest
	) -> Result<DecompileUnknownTransactionIntentResponse, Error> {
		callLibraryFunction(
			request: request,
			function: decompile_unknown_transaction_intent
		)
	}

	func decodeAddressRequest(
		request: DecodeAddressRequest
	) -> Result<DecodeAddressResponse, Error> {
		callLibraryFunction(
			request: request,
			function: decode_address
		)
	}

	func encodeAddressRequest(
		request: EncodeAddressRequest
	) -> Result<EncodeAddressResponse, Error> {
		callLibraryFunction(
			request: request,
			function: encode_address
		)
	}

	func sborDecodeRequest(
		request: SborDecodeRequest
	) -> Result<SborDecodeResponse, Error> {
		callLibraryFunction(
			request: request,
			function: sbor_decode
		)
	}

	func sborEncodeRequest(
		request: SborEncodeRequest
	) -> Result<SborEncodeResponse, Error> {
		callLibraryFunction(
			request: request,
			function: sbor_encode
		)
	}

	func deriveNonFungibleGlobalIdFromPublicKeyRequest(
		request: DeriveNonFungibleGlobalIdFromPublicKeyRequest
	) -> Result<DeriveNonFungibleGlobalIdFromPublicKeyResponse, Error> {
		callLibraryFunction(
			request: request,
			function: derive_non_fungible_global_id_from_public_key
		)
	}

	func deriveVirtualAccountAddressRequest(
		request: DeriveVirtualAccountAddressRequest
	) -> Result<DeriveVirtualAccountAddressResponse, Error> {
		callLibraryFunction(
			request: request,
			function: derive_virtual_account_address
		)
	}

	func deriveVirtualIdentityAddressRequest(
		request: DeriveVirtualIdentityAddressRequest
	) -> Result<DeriveVirtualIdentityAddressResponse, Error> {
		callLibraryFunction(
			request: request,
			function: derive_virtual_identity_address
		)
	}

	func knownEntityAddresses(
		request: KnownEntityAddressesRequest
	) -> Result<KnownEntityAddressesResponse, Error> {
		callLibraryFunction(
			request: request,
			function: known_entity_addresses
		)
	}
}

// MARK: Private (But Internal For Tests)

internal extension EngineToolkit {
	/// Calls the transaction library with a given input and returns the output back.
	///
	/// This function abstracts away how the transaction library is called and provides a high level interface for
	/// communicating and getting responses back from the library.
	func callLibraryFunction<Request, Response>(
		request: Request,
		function: (MutableToolkitPointer?) -> MutableToolkitPointer?
	) -> Result<Response, Error> where Request: Encodable, Response: Decodable {
		// Serialize the given request to a JSON string.
		serialize(request: request)
			.mapError(Error.serializeRequestFailure)
			.flatMap { (requestString: String) in
				#if DEBUG
				prettyPrintRequest(jsonString: requestString)
				#endif

				// Allocate enough memory for the request string and then write it to
				// that memory location
				return allocateMemoryForJSONStringOf(request: requestString)
					.map { requestPointer in
						writeJSONString(of: requestString, to: requestPointer)
					}
					.mapError(Error.callLibraryFunctionFailure)
			}
			.flatMap { (requestPointer: MutableToolkitPointer) in
				// Calling the underlying transaction library function and getting a pointer
				// response. We cannot deallocated the `responsePointer`, it results in a crash.
				guard let responsePointer = function(requestPointer) else {
					// Deallocate memory on failure (no response).
					deallocateMemoryOfNullTerminatedString(pointer: requestPointer)

					return .failure(Error.callLibraryFunctionFailure(.noReturnedOutputFromLibraryFunction))
				}
				return .success((requestPointer, responsePointer))
			}
			.flatMap { (requestPointer: MutableToolkitPointer, responsePointer: MutableToolkitPointer) in

				let responseJSONString = jsonStringOfResponse(at: responsePointer)

				#if DEBUG
				prettyPrintResponse(jsonString: responseJSONString)
				#endif

				// Deallocating the request and response memory
				deallocateMemoryOfNullTerminatedString(pointer: requestPointer)
				deallocateMemoryOfNullTerminatedString(pointer: responsePointer)

				// Deserialize response
				return deserialize(jsonString: responseJSONString)
					.mapError(Error.deserializeResponseFailure)
			}
	}
}

private extension EngineToolkit {
	/// Serializes an object to a JSON string.
	///
	/// This private function takes an object and serializes it to a JSON string. In the current implementation, this
	/// object needs to be `Encodable`, therefore, this function abstracts the serialization logic away from the
	/// transaction library operations and into an individual function.
	func serialize(request: any Encodable) -> Result<String, Error.SerializeRequestFailure> {
		let jsonData: Data
		do {
			jsonData = try jsonEncoder.encode(request)
		} catch {
			return .failure(.jsonEncodeRequestFailed)
		}
		guard let jsonString = jsonStringFromJSONData(jsonData) else {
			return .failure(.utf8DecodingFailed)
		}
		return .success(jsonString)
	}

	/// Deserializes a JSON string to a generic `T`.
	///
	/// This function deserializes a JSON string to a generic `T` which is defined by the of this function. It is
	/// assumed that the deserialization does not fail since the payload is a trusted payload.
	///
	/// TODO: In the future, it would be better to have this a `Result<T, Error>` since there is a chance
	/// that this could be an error type as well and not an Ok response.
	func deserialize<Response>(jsonString: String) -> Result<Response, Error.DeserializeResponseFailure>
		where Response: Decodable
	{
		guard let jsonData = jsonDataFromJSONString(jsonString) else {
			return .failure(.beforeDecodingError(.failedToUTF8EncodeResponseJSONString))
		}

		do {
			let response = try jsonDecoder.decode(Response.self, from: jsonData)
			return .success(response)
		} catch let firstError {
			guard let str = String(data: jsonData, encoding: .utf8) else {
				#if DEBUG
				prettyPrint(responseJSONString: jsonString, error: firstError, failedToDecodeInto: Response.self)
				#endif
				return .failure(.decodeResponseFailedAndCouldNotDecodeAsErrorResponseEitherNorAsSwiftDecodingError(responseType: "\(Response.self)", nonSwiftDecodingError: String(describing: firstError)))
			}
			return .failure(.errorResponse(str))
		}
	}

	/// Allocates memory of the defined capacity through the library's memory allocator
	///
	/// **Note:**
	///
	/// Only one memory allocator should be used at a time, and in most cases, when using the Radix Engine Toolkit
	/// this would be the allocator provided by the library. Using multiple allocators can lead to memory corruption
	/// issues and potential memory leaks if memory is not handeled correctly.
	func allocateMemory(capacity: UInt) -> Result<MutableToolkitPointer, Error.CallLibraryFunctionFailure> {
		if let allocatedMemory = toolkit_alloc(capacity) {
			return .success(allocatedMemory)
		} else {
			return .failure(.noReturnedOutputFromLibraryFunction)
		}
	}

	/// Allocates memory for the C-String UTF-8 encoded representation of the passed string
	///
	/// **Note: **
	///
	/// Only one memory allocator should be used at a time, and in most cases, when using the Radix Engine Toolkit
	/// this would be the allocator provided by the library. Using multiple allocators can lead to memory corruption
	/// issues and potential memory leaks if memory is not handeled correctly.
	func allocateMemoryForJSONStringOf(request requestJSONString: String) -> Result<MutableToolkitPointer, Error.CallLibraryFunctionFailure> {
		// Get the byte count of the C-String representation of the utf-8 encoded
		// string.
		let cString = Array(requestJSONString.utf8CString)

		let byteCount: Int = cString.count
		return allocateMemory(capacity: UInt(byteCount))
	}

	/// Deallocates memory starting from the provided memory pointer and until (including) the first null terminator.
	/// Thus, this function operates with the assumption that the memory location stores a null-terminated C-String.
	///
	/// This function deallocates memory which was previously allocated by the transaction library memory allocator.
	/// There are no returns from this function since it is assumed that the memory deallocation will always succeed.
	///
	/// **Note: **
	///
	/// Only one memory allocator should be used at a time, and in most cases, when using the Radix Engine Toolkit
	/// this would be the allocator provided by the library. Using multiple allocators can lead to memory corruption
	/// issues and potential memory leaks if memory is not handeled correctly.
	func deallocateMemoryOfNullTerminatedString(pointer: MutableToolkitPointer) {
		toolkit_free_c_string(pointer)
	}

	/// Writes the string to the memory location provided.
	///
	/// This function writes the C-String representation of the passed string to the provided pointer. Since this is a C-String
	/// representation, this means that an additional byte is added at the end with the null terminator.
	@discardableResult
	func writeJSONString(
		of requestJSONString: String,
		to pointer: MutableToolkitPointer
	) -> MutableToolkitPointer {
		// Converting the request JSON string to an array of UTF-8 bytes
		let requestChars = requestJSONString.utf8CString

		// Iterating over the array and writing all of the bytes to memory
		for (charIndex, cChar) in requestChars.enumerated() {
			pointer.advanced(by: charIndex).pointee = cChar
		}

		return pointer
	}

	/// Reads a string from the provided memory location.
	///
	/// This function reads a C-String, null terminated, string from the provided memory location and returns it.
	func jsonStringOfResponse(
		at pointer: ImmutableToolkitPointer
	) -> String {
		String(cString: pointer)
	}
}

#if DEBUG

func prettyPrintRequest(jsonString: String) {
	prettyPrint(jsonString: jsonString, label: "\n📦⬆️ Request JSON string")
}

func prettyPrintResponse(jsonString: String) {
	prettyPrint(jsonString: jsonString, label: "\n📦⬇️ Response JSON string (prettified before JSON decoding)")
}

func prettyPrint<FailedDecodable: Decodable>(
	responseJSONString: String,
	error: Swift.Error,
	failedToDecodeInto: FailedDecodable.Type
) {
	prettyPrint(
		jsonString: responseJSONString,
		label: "\n📦⬇️ Failed to parse response JSON string to either \(FailedDecodable.self) or ErrorResponse, underlying decoding error: \(String(describing: error))"
	)
}

/// Tries to pretty prints JSON string even before Decodable JSON decoding takes place
/// using old Cocoa APIs
func prettyPrint(jsonString: String, label: String?) {
	guard
		EngineToolkit._debugPrint,
		let data = jsonString.data(using: .utf8),
		let pretty = data.prettyPrintedJSONString
	else {
		return
	}
	if let label {
		debugPrint(label)
	}
	debugPrint(pretty)
}
#endif
