import CasePaths
import Cryptography

import JSONTesting
@testable import Profile
import RadixConnectModels
import SharedTestingModels
import SwiftUI
import TestingPrelude

// MARK: - PersonaFieldTests
final class PersonaFieldTests: TestCase {
	func test_name_western() throws {
		let personaData = withDependencies {
			$0.uuid = .incrementing
		} operation: {
			PersonaData(
				name: .init(
					value: .init(
						variant: .western,
						familyName: "Kennedy",
						givenNames: "John",
						nickname: "Fitzgerald"
					)
				)
			)
		}

		let aName = try dappRequest(value: \.name, from: personaData)
		XCTAssertEqual(aName.value.valueForDapp, "John Fitzgerald Kennedy")
	}

	func test_name_eastern() throws {
		let personaData = withDependencies {
			$0.uuid = .incrementing
		} operation: {
			PersonaData(
				name: .init(
					value: .init(
						variant: .eastern,
						familyName: "Park",
						givenNames: "Chan-wook"
					)
				)
			)
		}
		let aName = try dappRequest(value: \.name, from: personaData)
		XCTAssertEqual(aName.value.valueForDapp, "Park Chan-wook")
	}

	func test_email_addresses() throws {
		let personaData = withDependencies {
			$0.uuid = .incrementing
		} operation: {
			PersonaData(
				emailAddresses: [
					.init(value: "hi@rdx.works"),
					.init(value: "bye@rdx.works"),
				]
			)
		}

		let emails = try dappRequest(values: \.emailAddresses, from: personaData)
		XCTAssertEqual(emails.map(\.value), ["hi@rdx.works", "bye@rdx.works"])
	}

	func test_assert_personaData_fieldCollectionOf_cannot_contain_duplicated_values() {
		XCTAssertThrowsError(
			try PersonaData.IdentifiedEmailAddresses(
				collection: [
					.init(id: .init(uuidString: "BBBBBBBB-0000-1111-2222-BBBBBBBBBBBB"), value: "hi@rdx.works"),
					.init(id: .init(uuidString: "AAAAAAAA-9999-8888-7777-AAAAAAAAAAAA"), value: "hi@rdx.works"), // same value cannot be used twice, even though UUID differs!
				]
			)
		)
	}

	func test_assert_personaData_fieldCollectionOf_cannot_add_duplicate_value() throws {
		var fieldCollection = try PersonaData.IdentifiedEmailAddresses(
			collection: [
				.init(id: .init(uuidString: "BBBBBBBB-0000-1111-2222-BBBBBBBBBBBB"), value: "hi@rdx.works"),
			]
		)
		XCTAssertThrowsError(
			try fieldCollection.add(
				.init(id: .init(uuidString: "AAAAAAAA-9999-8888-7777-AAAAAAAAAAAA"), value: "hi@rdx.works")
			)
		)
	}

	func test_assert_personaData_fieldCollectionOf_cannot_add_duplicate_id() throws {
		var fieldCollection = try PersonaData.IdentifiedEmailAddresses(
			collection: [
				.init(id: .init(uuidString: "BBBBBBBB-0000-1111-2222-BBBBBBBBBBBB"), value: "hi@rdx.works"),
			]
		)
		XCTAssertThrowsError(
			try fieldCollection.add(
				.init(id: .init(uuidString: "BBBBBBBB-0000-1111-2222-BBBBBBBBBBBB"), value: "bye@rdx.works")
			)
		)
	}

	func test_assert_personaData_fieldCollectionOf_can_add_another_value() throws {
		var fieldCollection = try PersonaData.IdentifiedEmailAddresses(
			collection: [
				.init(id: .init(uuidString: "BBBBBBBB-0000-1111-2222-BBBBBBBBBBBB"), value: "hi@rdx.works"),
			]
		)
		try fieldCollection.add(
			.init(id: .init(uuidString: "AAAAAAAA-9999-8888-7777-AAAAAAAAAAAA"), value: "bye@rdx.works")
		)
		XCTAssertEqual(fieldCollection.map(\.value), ["hi@rdx.works", "bye@rdx.works"])
	}

	func test_update_emails() throws {
		var email = PersonaData.IdentifiedEmailAddresses.Element(
			id: .init(uuidString: "BBBBBBBB-0000-1111-2222-BBBBBBBBBBBB"),
			value: "hi@rdx.works"
		)
		var fieldCollection = try PersonaData.IdentifiedEmailAddresses(
			collection: [
				email,
			]
		)
		email.value = "bye@rdx.works"
		XCTAssertNoThrow(try fieldCollection.update(email))
		XCTAssertEqual(fieldCollection[0].value, "bye@rdx.works")
	}

	func test_assert_update_unknown_id_throws() throws {
		var fieldCollection = try PersonaData.IdentifiedEmailAddresses(
			collection: [
				.init(id: .init(uuidString: "AAAAAAAA-9999-8888-7777-AAAAAAAAAAAA"), value: "hi@rdx.works"),
			]
		)
		XCTAssertThrowsError(try fieldCollection.update(.init(
			id: .init(uuidString: "BBBBBBBB-0000-1111-2222-BBBBBBBBBBBB"),
			value: "bye@rdx.works"
		)))
	}

	func test_postalAddress_sweden() throws {
		try withDependencies {
			$0.uuid = .constant(.init())
		} operation: {
			let personaData = PersonaData(
				name: .init(
					value: .init(
						variant: .western,
						familyName: "Palme",
						givenNames: "Olof"
					)
				),
				postalAddresses: [[
					.streetLine0("Västerlånggatan 31"),
					.streetLine1(""),
					.postalCode("11129"), .city("Stockholm"),
					.countryOrRegion(.sweden),
				]]
			)

			let addresses = try dappRequest(values: \.postalAddresses, from: personaData)
			XCTAssertEqual(addresses[0], [
				.streetLine0("Västerlånggatan 31"),
				.streetLine1(""),
				.postalCode("11129"), .city("Stockholm"),
				.countryOrRegion(.sweden),
			])
		}
	}

	func test_multiple_postalAddresses_multiple() throws {
		let personaData = withDependencies {
			$0.uuid = .incrementing
		} operation: {
			PersonaData(
				postalAddresses: [
					[
						.streetLine0("Östantorp Vinö 52"),
						.streetLine1(),
						.postalCode("36030"), .city("Lammhult"),
						.countryOrRegion(.sweden),
					],
					[
						.streetLine0("Föreningsgatan 41"),
						.streetLine1(),
						.postalCode("86033"), .city("Bergeforsen"),
						.countryOrRegion(.sweden),
					],
					[
						.streetLine0("93 rue de la Mare aux Carats"),
						.streetLine1(),
						.postalCode("34080"), .city("Montpellier"),
						.countryOrRegion(.france),
					],
					[
						.streetLine0("34 St Thomas's Rd"),
						.streetLine1(),
						.townSlashCity("Gosport"),
						.county("Hampshire"),
						.postcode("PO12 4JX"),
						.countryOrRegion(.unitedKingdom),
					],
				]
			)
		}

		let addresses = try dappRequest(values: \.postalAddresses, from: personaData)
		XCTAssertEqual(addresses.compactMap(\.value.countryOrRegion), [.sweden, .sweden, .france, .unitedKingdom])
	}

	func test_invalid_postalAddress_japan() throws {
		XCTAssertThrowsError(
			try PersonaData.PostalAddress(
				validating: [
					.countryOrRegion(.japan),
					.streetLine0("Should not use 'streetLine'"),
					.streetLine1("Should not use 'streetLine'"),
					.postalCode("123"),
					.city("Tokyo"),
				]
			)
		)
	}

	func test_json_coding_personaData() throws {
		let personaData = withDependencies {
			$0.uuid = .incrementing
		} operation: {
			PersonaData.previewValue
		}

		let personaJSON: JSON = [
			"companyName": [
				"id": "00000000-0000-0000-0000-000000000002",
				"value": "Bitcoin",
			],
			"creditCards": [
				[
					"id": "00000000-0000-0000-0000-00000000000B",
					"value": [
						"cvc": 512,
						"expiry": [
							"month": 12,
							"year": 2142,
						],
						"holder": "Satoshi Nakamoto",
						"number": "0000 0000 2100 0000",
					],
				],
			],
			"dateOfBirth": [
				"id": "00000000-0000-0000-0000-000000000001",
				"value": "2009-01-03T12:00:00Z",
			],
			"emailAddresses": [
				[
					"id": "00000000-0000-0000-0000-000000000003",
					"value": "satoshi@nakamoto.bitcoin",
				],
				[
					"id": "00000000-0000-0000-0000-000000000004",
					"value": "be.your@own.bank",
				],
			],
			"name": [
				"id": "00000000-0000-0000-0000-000000000000",
				"value": [
					"family": "Nakamoto",
					"given": "Satoshi",
					"middle": "Creator of Bitcoin",
					"variant": "eastern",
				],
			],
			"phoneNumbers": [
				[
					"id": "00000000-0000-0000-0000-000000000005",
					"value": "21000000",
				],
				[
					"id": "00000000-0000-0000-0000-000000000006",
					"value": "123456789",
				],
			],
			"postalAddresses": [
				[
					"id": "00000000-0000-0000-0000-000000000009",
					"value": [
						[
							"discriminator": "postalCode",
							"value": "21 000 000",
						],
						[
							"discriminator": "prefecture",
							"value": "SHA256",
						],
						[
							"discriminator": "countySlashCity",
							"value": "Hashtown",
						],
						[
							"discriminator": "furtherDivisionsLine0",
							"value": "Sound money street",
						],
						[
							"discriminator": "furtherDivisionsLine1",
							"value": "",
						],
						[
							"discriminator": "countryOrRegion",
							"value": "japan",
						],
					],
				],
				[
					"id": "00000000-0000-0000-0000-00000000000A",
					"value": [
						[
							"discriminator": "streetLine0",
							"value": "Copthall House",
						],
						[
							"discriminator": "streetLine1",
							"value": "King street",
						],
						[
							"discriminator": "townSlashCity",
							"value": "Newcastle-under-Lyme",
						],
						[
							"discriminator": "county",
							"value": "Newcastle",
						],
						[
							"discriminator": "postcode",
							"value": "ST5 1UE",
						],
						[
							"discriminator": "countryOrRegion",
							"value": "unitedKingdom",
						],
					],
				],
			],
			"urls": [
				[
					"id": "00000000-0000-0000-0000-000000000007",
					"value": "bitcoin.org",
				],
				[
					"id": "00000000-0000-0000-0000-000000000008",
					"value": "https://github.com/bitcoin-core/secp256k1",
				],
			],
		]

		let encoder = JSONEncoder()
		encoder.outputFormatting = [.sortedKeys]

		try XCTAssertJSONEncoding(
			personaData,
			personaJSON,
			encoder: encoder
		)

		try XCTAssertJSONDecoding(
			personaJSON,
			personaData
		)
	}
}

// MARK: - PersonaData.IdentifiedEntry + ExpressibleByStringLiteral, ExpressibleByUnicodeScalarLiteral, ExpressibleByExtendedGraphemeClusterLiteral
extension PersonaData.IdentifiedEntry<PersonaData.EmailAddress>: ExpressibleByStringLiteral, ExpressibleByUnicodeScalarLiteral, ExpressibleByExtendedGraphemeClusterLiteral {
	public init(stringLiteral value: String) {
		self.init(value: .init(email: value))
	}
}

// MARK: - PersonaData.PostalAddress + ExpressibleByArrayLiteral
extension PersonaData.PostalAddress: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: PersonaData.PostalAddress.Field...) {
		try! self.init(validating: .init(uncheckedUniqueElements: elements))
	}
}

// MARK: - PersonaData.IdentifiedEntry + ExpressibleByArrayLiteral
extension PersonaData.IdentifiedEntry<PersonaData.PostalAddress>: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: PersonaData.PostalAddress.Field...) {
		try! self.init(value: .init(validating: .init(uncheckedUniqueElements: elements)))
	}
}

private extension PersonaFieldTests {
	func dappRequest<Kind: PersonaDataEntryProtocol>(
		values keyPath: KeyPath<PersonaData, PersonaData.CollectionOfIdentifiedEntries<Kind>>,
		from personaData: PersonaData
	) throws -> PersonaData.CollectionOfIdentifiedEntries<Kind> {
		personaData[keyPath: keyPath]
	}

	func dappRequest<Kind: PersonaDataEntryProtocol>(
		value keyPath: KeyPath<PersonaData, PersonaData.IdentifiedEntry<Kind>?>,
		from personaData: PersonaData
	) throws -> PersonaData.IdentifiedEntry<Kind> {
		guard let field = personaData[keyPath: keyPath] else {
			throw NoSuchField()
		}
		return field
	}
}

// MARK: - NoSuchField
struct NoSuchField: Error {}

extension PersonaData.Name {
	public var valueForDapp: String {
		description
	}
}

// MARK: - PersonaData.EmailAddress + ExpressibleByStringLiteral
extension PersonaData.EmailAddress: ExpressibleByStringLiteral {
	public init(stringLiteral value: String) {
		self.init(email: value)
	}
}

// MARK: - PersonaData.CollectionOfIdentifiedEntries + ExpressibleByArrayLiteral
extension PersonaData.CollectionOfIdentifiedEntries: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: PersonaData.IdentifiedEntry<Value>...) {
		try! self.init(collection: .init(uncheckedUniqueElements: elements))
	}
}
