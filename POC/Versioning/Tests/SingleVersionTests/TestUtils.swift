import Foundation
@testable import SingleVersion
import XCTest

extension XCTestCase {
	func assertSuccessfulDecoding<T: Decodable>(
		json: String,
		type: T.Type = T.self,
		line: UInt = #line,
		file: StaticString = #filePath,
		assert: (T) throws -> Void
	) throws {
		let jsonDecoder = JSONDecoder()
		let migrated: T
		do {
			migrated = try jsonDecoder.decode(T.self, from: json.data(using: .utf8)!)
		} catch {
			XCTFail("Unexpected decoding error: \(String(describing: error))", file: file, line: line)
			return
		}
		try assert(migrated)
	}

	func assertFailingDecoding<T: Decodable>(
		json: String,
		type: T.Type = T.self
	) {
		let jsonDecoder = JSONDecoder()
		XCTAssertThrowsError(
			try jsonDecoder.decode(T.self, from: json.data(using: .utf8)!)
		)
	}
}
