@testable import EngineToolkit
import Prelude
import XCTest

func XCTAssertThrowsFailure<Success, Failure: Swift.Error & Equatable>(
	_ expression: @autoclosure () -> Result<Success, Failure>,
	_ message: @autoclosure () -> String = "",
	file: StaticString = #filePath,
	line: UInt = #line,
	_ errorHandler: (_ failure: Failure) -> Void = { _ in }
) {
	let result = expression()

	let assertFailureTypeResult = result.mapError { (failure: Failure) -> Failure in
		errorHandler(failure)
		return failure
	}

	XCTAssertThrowsError(
		try assertFailureTypeResult.get(),
		message(),
		file: file,
		line: line
	)
}

func XCTAssertThrowsEngineError<Success>(
	_ expression: @autoclosure () -> Result<Success, EngineToolkit.Error>,
	_ message: @autoclosure () -> String = "",
	file: StaticString = #filePath,
	line: UInt = #line,
	_ errorHandler: (_ failure: EngineToolkit.Error) -> Void = { _ in }
) {
	XCTAssertThrowsFailure(
		expression(),
		message(),
		file: file,
		line: line,
		errorHandler
	)
}

func XCTAssert<Success>(
	_ expression: @autoclosure () -> Result<Success, EngineToolkit.Error>,
	throwsSpecificError specificError: EngineToolkit.Error,
	_ message: @autoclosure () -> String = "",
	file: StaticString = #filePath,
	line: UInt = #line
) {
	XCTAssertThrowsFailure(
		expression(),
		message(),
		file: file,
		line: line
	) { failure in
		XCTAssertNoDifference(failure, specificError, message(), file: file, line: line)
	}
}

func XCTCast<To>(
	to _: To.Type,
	from any: Any,
	file: StaticString = #file,
	line: UInt = #line
) -> To? {
	try? XCTUnwrap(any as? To, "Failed to cast to: \(To.self) from: \(any)")
}

func XCTCast<To>(
	from any: Any,
	file: StaticString = #file,
	line: UInt = #line
) -> To? {
	XCTCast(to: To.self, from: any, file: file, line: line)
}

func XCTAssert<T, E: Swift.Error & Equatable>(
	error expectedError: E,
	thrownBy expression: @autoclosure () throws -> T,
	_ message: @autoclosure () -> String = "",
	file: StaticString = #file,
	line: UInt = #line
) {
	XCTAssertThrowsError(
		try expression(),
		message(),
		file: file,
		line: line
	) {
		XCTAssertNoDifference(expectedError, XCTCast(to: E.self, from: $0))
	}
}
