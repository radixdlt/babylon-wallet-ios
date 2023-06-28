import JSONTesting
@testable import SingleVersion
import XCTest

// MARK: - SingleVersionTests
final class SingleVersionTests: XCTestCase {
	// MARK: Encoding
	func test_encoding() throws {
		let trivial2 = Trivial2(label: "test", foo: "encoding")
		try XCTAssertJSONEncoding(trivial2, [
			"version": 2,
			"label": "test",
			"foo": "encoding",
		])
	}

	// MARK: Decoding
	func test_decoding_migration_1_to_2() throws {
		try assertSuccessfulDecoding(
			json: """
			{
				"version": 1,
				"label": "test"
			}
			"""
		) { (migrated: Trivial2) in
			XCTAssertEqual(migrated.foo, "MIGRATED_FROM_1")

			try XCTAssertJSONEncoding(migrated, [
				"version": 2,
				"label": "test",
				"foo": "MIGRATED_FROM_1",
			])
		}
	}

	func test_decoding_fail_no_version() {
		assertFailingDecoding(
			json: """
			{
				"label": "test"
			}
			""",
			type: Trivial2.self
		)
	}

	func test_decoding_fail_version_unknown_too_low() {
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

	func test_decoding_fail_version_unknown_too_high() {
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

	func test_decoding_fail_correct_version_missing_other_property() {
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
