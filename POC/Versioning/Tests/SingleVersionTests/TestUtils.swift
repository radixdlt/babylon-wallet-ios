import Foundation
@testable import SingleVersion
import XCTest

extension XCTestCase {
	func assertSuccessfulDecoding<T: VersionedCodable>(
		json: String,
		type: T.Type = T.self,
		assert: (T) throws -> Void
	) throws {
		let jsonDecoder = JSONDecoder()
		let migrated = try jsonDecoder.decode(T.self, from: json.data(using: .utf8)!)
		XCTAssertEqual(migrated.version, Trivial2.minVersion)
		try assert(migrated)
	}

	func assertFailingDecoding<T: VersionedCodable>(
		json: String,
		type: T.Type = T.self
	) {
		let jsonDecoder = JSONDecoder()
		XCTAssertThrowsError(
			try jsonDecoder.decode(T.self, from: json.data(using: .utf8)!)
		)
	}
}
