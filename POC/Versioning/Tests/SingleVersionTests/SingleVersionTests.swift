@testable import SingleVersion
import XCTest

// MARK: - SingleVersionTests
final class SingleVersionTests: XCTestCase {
	func test_migration_1_to_2() throws {
		try assertSuccessfulDecoding(
			json: """
			{
				"version": 1,
				"label": "test"
			}
			"""
		) { (migrated: Trivial2) in
			XCTAssertEqual(migrated.foo, "MIGRATED_FROM_1")
		}
	}

	func test_fail_no_version() {
		assertFailingDecoding(
			json: """
			{
				"label": "test"
			}
			""",
			type: Trivial2.self
		)
	}

	func test_fail_version_unknown_too_low() {
		assertFailingDecoding(
			json: """
			{
				"version": 0,
				"label": "test"
			}
			""",
			type: Trivial2.self
		)
	}

	func test_fail_version_unknown_too_high() {
		assertFailingDecoding(
			json: """
			{
				"version": 9,
				"label": "test"
			}
			""",
			type: Trivial2.self
		)
	}

	func test_fail_correct_version_missing_other_property() {
		assertFailingDecoding(
			json: """
			{
				"version": 2
			}
			""",
			type: Trivial2.self
		)
	}
}

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
