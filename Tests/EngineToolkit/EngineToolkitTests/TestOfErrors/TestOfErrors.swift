@testable import EngineToolkit
import Prelude
import XCTest

// MARK: - TestOfErrors
final class TestOfErrors: TestCase {
	// MARK: From EngineToolkit
	func test_error_serializeRequestFailure_utf8Decode() throws {
		let sut = EngineToolkit(jsonStringFromJSONData: { _ in nil /* utf8 decode fail */ })
		XCTAssert(
			sut.information(),
			throwsSpecificError: .serializeRequestFailure(.utf8DecodingFailed)
		)
	}

	func test_error_serializeRequestFailure_jsonEncodeRequestFailed() throws {
		let sut = EngineToolkit(jsonEncoder: FailingJSONEncoder())
		XCTAssert(
			sut.information(),
			throwsSpecificError: .serializeRequestFailure(.jsonEncodeRequestFailed)
		)
	}

	func test_error_callLibraryFunctionFailure_no_output_from_function() throws {
		let sut = EngineToolkit()

		// Have to use otherwise private method `callLibraryFunction` to mock mo response from `function`.
		let emptyResult: Result<InformationResponse, EngineToolkit.Error> = sut.callLibraryFunction(
			request: InformationRequest(),
			function: { _ in nil /* mock nil response */ }
		)

		XCTAssert(
			emptyResult,
			throwsSpecificError: .callLibraryFunctionFailure(.noReturnedOutputFromLibraryFunction)
		)
	}

	func test_error_deserializeResponseFailure_utf8EncodingFailed() throws {
		let sut = EngineToolkit(jsonDataFromJSONString: { _ in nil /* utf8 encode fail */ })
		XCTAssert(
			sut.information(),
			throwsSpecificError: .deserializeResponseFailure(.beforeDecodingError(.failedToUTF8EncodeResponseJSONString))
		)
	}

	func test_error_deserializeResponseFailure_jsonDecodeFail_non_swiftDecodingError() throws {
		let failingMockErrorDecoder = FailingJSONDecoder()
		let sut = EngineToolkit(jsonDecoder: failingMockErrorDecoder)
		XCTAssert(
			sut.information(),
			throwsSpecificError: .deserializeResponseFailure(
				.decodeResponseFailedAndCouldNotDecodeAsErrorResponseEitherNorAsSwiftDecodingError(
					responseType: "\(InformationResponse.self)",
					nonSwiftDecodingError: MockError.jsonDecodeFail.rawValue
				)
			)
		)
	}

	func test_error_deserializeResponseFailure_jsonDecodeFail_swiftDecodingError() throws {
		let failingSwiftDecodingErrorDecoder = FailingJSONDecoderSwiftDecodingError()
		let sut = EngineToolkit(jsonDecoder: failingSwiftDecodingErrorDecoder)
		XCTAssert(
			sut.information(),
			throwsSpecificError: .deserializeResponseFailure(
				.decodeResponseFailedAndCouldNotDecodeAsErrorResponseEither(
					responseType: "\(InformationResponse.self)",
					decodingError: .mock
				)
			)
		)
	}

	func test_json_parse_address_error() throws {
		let json = """
		{
		  "error" : "AddressError",
		  "value" : "DecodingError(MissingSeparator)"
		}
		""".data(using: .utf8)!
		let addressError = try JSONDecoder().decode(AddressError.self, from: json)
		XCTAssertNoDifference(addressError, AddressError(value: "DecodingError(MissingSeparator)"))
	}

	func test_json_parse_errorResponse() throws {
		let json = """
		{
		  "error" : "AddressError",
		  "value" : "DecodingError(MissingSeparator)"
		}
		""".data(using: .utf8)!
		let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: json)
		XCTAssertNoDifference(errorResponse, .addressError(AddressError(value: "DecodingError(MissingSeparator)")))
	}

	// MARK: ErrorResponse (from RET)
	func test_assert_that_decodeAddress_badRequest_missing_separator_throws_addressError_nested_DecodingError_missing_separator() throws {
		let badRequest = DecodeAddressRequest(address: "missing separator")
		let result = sut.decodeAddressRequest(request: badRequest)
		let expectedErrorResponse: ErrorResponse = .addressError(AddressError(value: "Bech32mDecodingError(MissingSeparator)"))
		XCTAssert(
			result,
			throwsSpecificError: .deserializeResponseFailure(.errorResponse(expectedErrorResponse))
		)
	}

	func test_assert_that_decodeAddress_badRequest_missing_separator_throws_addressError_nested_DecodingError_invalid_char_space() throws {
		let badRequest = DecodeAddressRequest(address: "bad1 invalid char spaces")
		let result = sut.decodeAddressRequest(request: badRequest)
		let expectedErrorResponse: ErrorResponse = .addressError(AddressError(value: "Bech32mDecodingError(InvalidChar(' '))"))
		XCTAssert(
			result,
			throwsSpecificError: .deserializeResponseFailure(.errorResponse(expectedErrorResponse))
		)
	}

	func test_assert_that_decodeAddress_badRequest_missing_separator_throws_addressError_nested_DecodingError_invalid_checksum() throws {
		let badRequest = DecodeAddressRequest(address: "invalid1checksum")
		let result = sut.decodeAddressRequest(request: badRequest)
		let expectedErrorResponse: ErrorResponse = .addressError(AddressError(value: "Bech32mDecodingError(InvalidChecksum)"))
		XCTAssert(
			result,
			throwsSpecificError: .deserializeResponseFailure(.errorResponse(expectedErrorResponse))
		)
	}
}

// MARK: - MockError
enum MockError: String, Error {
	case jsonEncodeFail
	case jsonDecodeFail
}

// MARK: - FailingJSONEncoder
final class FailingJSONEncoder: JSONEncoder {
	override func encode<T>(_ value: T) throws -> Data where T: Encodable {
		throw MockError.jsonEncodeFail
	}
}

// MARK: - ManualDecodeFailure
struct ManualDecodeFailure: Error {}

// MARK: - FailingJSONDecoder
final class FailingJSONDecoder: JSONDecoder {
	override func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
		throw MockError.jsonDecodeFail
	}
}

// MARK: - FailingJSONDecoderSwiftDecodingError
final class FailingJSONDecoderSwiftDecodingError: JSONDecoder {
	override func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
		throw Swift.DecodingError.mock
	}
}

extension Swift.DecodingError {
	static let mock = Self.dataCorrupted(Context.mock)
}

extension Swift.DecodingError.Context {
	static let mock = Self(codingPath: [], debugDescription: "Mock")
}
