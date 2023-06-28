@testable import MultipleTypesForEachModelVersionedCodable
import TestUtils

final class MultipleTypesForEachModelVersionedCodableTests: XCTestCase {
	// MARK: Encoding
	func test_encoding() throws {
		let nested = Model(
			label: "test",
			inner: .init(
				innerGeneric: .init(value: "Value=String.self")
			),
			anotherInner: .init(bizz: "buzz")
		)
		try XCTAssertJSONEncoding(
			versioned: nested,
			[
				"version": 3,
				"label": "test",
				"inner": [
					"innerGeneric": [
						"value": "Value=String.self",
					],
				],
				"anotherInner": [
					"bizz": "buzz",
				],
			]
		)
	}

	// MARK: Decoding

	func test_decoding_3() throws {
		try XCTAssertJSONDecoding(
			[
				"version": 3,
				"label": "test",
				"inner": [
					"innerGeneric": [
						"value": "Value=String.self",
					],
				],
				"anotherInner": [
					"bizz": "buzz",
				],
			],
			Model(
				label: "test",
				inner: .init(
					innerGeneric: .init(value: "Value=String.self")
				),
				anotherInner: .init(bizz: "buzz")
			)
		)
	}

	func test_decoding_migration_2_to_3() throws {
		try XCTAssertJSONDecoding(
			versioned: [
				"version": 2,
				"label": "test",
				"inner": [
					"innerGeneric": [
						"value": "Value=String.self",
					],
				],
			],
			Model(
				label: "test",
				inner: .init(
					innerGeneric: .init(value: "Value=String.self")
				),
				anotherInner: .init(bizz: "MIGRATED_FROM_2")
			)
		)
	}

	func test_decoding_migration_1_to_3() throws {
		try XCTAssertJSONDecoding(
			versioned: [
				"version": 1,
				"label": "test",
				"inner": [
					"innerGeneric": [
						"valeu": "Value=String.self",
					],
				],
			],
			Model(
				label: "test",
				inner: .init(
					innerGeneric: .init(value: "Value=String.self")
				),
				anotherInner: .init(bizz: "MIGRATED_FROM_2")
			)
		)
	}

	func test_decoding_fail_no_version() {
		assertFailingDecoding(
			json: """
			{
				"label": "test"
			}
			""",
			type: Model.self
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
			type: Model.self
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
			type: Model.self
		)
	}

	func test_decoding_fail_correct_version_missing_other_property() {
		assertFailingDecoding(
			json: """
			{
				"version": 2
			}
			""",
			type: Model.self
		)
	}
}
