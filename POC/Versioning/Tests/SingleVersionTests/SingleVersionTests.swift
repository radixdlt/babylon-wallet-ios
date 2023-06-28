import JSONTesting
@testable import SingleVersion
import XCTest

final class NestedTests: XCTestCase {
	// MARK: Encoding
	func test_encoding() throws {
		let nested2 = Nested2(
			label: "test",
			inner: .init(
				foo: "nested",
				bar: "encoding"
			)
		)
		try XCTAssertJSONEncoding(nested2, [
			"version": 2,
			"label": "test",
			"inner": [
				"foo": "nested",
				"bar": "encoding",
			],
		])
	}

	// MARK: Decoding
	func test_decoding_migration_1_to_2() throws {
		try assertSuccessfulDecoding(
			json: """
			{
				"version": 1,
				"label": "test",
				"inner": {
					"foo": "decoding"
				}
			}
			"""
		) { (migrated: Nested2) in
			XCTAssertEqual(migrated.version, 2)
			XCTAssertEqual(migrated.inner.bar, "MIGRATED_FROM_1")
		}
	}

	func test_decoding_fail_no_version() {
		assertFailingDecoding(
			json: """
			{
				"label": "test"
			}
			""",
			type: Nested2.self
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
			type: Nested2.self
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
			type: Nested2.self
		)
	}

	func test_decoding_fail_correct_version_missing_other_property() {
		assertFailingDecoding(
			json: """
			{
				"version": 2
			}
			""",
			type: Nested2.self
		)
	}
}
