@testable import SingleTypeUniqueVersionNumberPerType
import TestUtils

final class SingleTypeUniqueVersionNumberPerTypeTests: XCTestCase {
	// MARK: Encoding
	func test_every_encoding() throws {
		let nested = Model(
			label: "test",
			inner: .init(
				foo: "nested",
				bar: "encoding"
			),
			anotherInner: .init(bizz: "buzz")
		)
		try XCTAssertJSONEncoding(nested, [
			"version": 2,
			"label": "test",
			"inner": [
				"version": 2,
				"foo": "nested",
				"bar": "encoding",
			],
			"anotherInner": [
				"version": 1,
				"bizz": "buzz",
			],
		])
	}

	// MARK: Decoding
	func test_every_decoding_2() throws {
		try XCTAssertJSONDecoding(
			[
				"version": 2,
				"label": "test",
				"inner": [
					"version": 2,
					"foo": "decoding",
					"bar": "test",
				],
				"anotherInner": [
					"version": 1,
					"bizz": "buzz",
				],
			],
			Model(
				version: 2,
				label: "test",
				inner: .init(
					foo: "decoding",
					bar: "test"
				),
				anotherInner: .init(bizz: "buzz")
			)
		)
	}

	func test_every_decoding_migration_1a_to_2() throws {
		try XCTAssertJSONDecoding(
			[
				"version": 1,
				"label": "test",
				"inner": [
					"version": 1,
					"foo": "decoding",
				],
			],
			Model(
				version: 2,
				label: "test",
				inner: .init(
					foo: "decoding",
					bar: "MIGRATED_FROM_1"
				),
				anotherInner: .init(bizz: "MIGRATED_FROM_1")
			)
		)
	}

	func test_every_decoding_migration_1b_to_2() throws {
		try XCTAssertJSONDecoding(
			[
				"version": 1,
				"label": "test",
				"inner": [
					"version": 2,
					"foo": "decoding",
					"bar": "test",
				],
			],
			Model(
				version: 2,
				label: "test",
				inner: .init(
					foo: "decoding",
					bar: "test"
				),
				anotherInner: .init(bizz: "MIGRATED_FROM_1")
			)
		)
	}

	func test_every_decoding_fail_no_version() {
		assertFailingDecoding(
			json: """
			{
				"label": "test"
			}
			""",
			type: Model.self
		)
	}

	func test_every_decoding_fail_version_unknown_too_low() {
		assertFailingDecoding(
			json: """
			{
				"version": 0,
				"label": "test"
			}
			""",
			type: Model.self
		)
	}

	func test_every_decoding_fail_version_unknown_too_high() {
		assertFailingDecoding(
			json: """
			{
				"version": 9,
				"label": "test"
			}
			""",
			type: Model.self
		)
	}

	func test_every_decoding_fail_correct_version_missing_other_property() {
		assertFailingDecoding(
			json: """
			{
				"version": 2
			}
			""",
			type: Model.self
		)
	}

	func test_every_decoding_fail_no_version_in_inner() {
		assertFailingDecoding(
			json: """
			{
				"version": 1,
				"label": "test",
				"inner": {
					"foo": "decoding",
				}
			}
			""",
			type: Model.self
		)
	}
}
