@testable import EngineToolkit
import Prelude
import TestingPrelude

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
