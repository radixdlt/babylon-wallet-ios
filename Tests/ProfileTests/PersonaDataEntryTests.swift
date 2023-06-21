import CasePaths
import Cryptography
import EngineToolkit
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
						given: "John",
						middle: "Fitzgerald",
						family: "Kennedy",
						variant: .western
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
						given: "Chan-wook",
						family: "Park",
						variant: .eastern
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
						given: "Olof",
						family: "Palme",
						variant: .western
					)
				),
				postalAddresses: [[
					.streetLine0("Västerlånggatan 31"),
					.streetLine1(""),
					.postalCodeNumber(11129), .city("Stockholm"),
					.country(.sweden),
				]]
			)

			let addresses = try dappRequest(values: \.postalAddresses, from: personaData)
			XCTAssertEqual(addresses[0], [
				.streetLine0("Västerlånggatan 31"),
				.streetLine1(""),
				.postalCodeNumber(11129), .city("Stockholm"),
				.country(.sweden),
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
						.postalCodeNumber(36030), .city("Lammhult"),
						.country(.sweden),
					],
					[
						.streetLine0("Föreningsgatan 41"),
						.streetLine1(),
						.postalCodeNumber(86033), .city("Bergeforsen"),
						.country(.sweden),
					],
					[
						.streetLine0("93 rue de la Mare aux Carats"),
						.streetLine1(),
						.postalCodeNumber(34080), .city("Montpellier"),
						.country(.france),
					],
					[
						.streetLine0("34 St Thomas's Rd"),
						.streetLine1(),
						.city("Gosport"),
						.county("Hampshire"),
						.postcodeString("PO12 4JX"),
						.country(.unitedKingdom),
					],
				]
			)
		}

		let addresses = try dappRequest(values: \.postalAddresses, from: personaData)
		XCTAssertEqual(addresses.compactMap(\.value.country), [.sweden, .sweden, .france, .unitedKingdom])
	}

	func test_invalid_postalAddress_japan() throws {
		XCTAssertThrowsError(
			try PersonaData.PostalAddress(
				validating: [
					.country(.japan),
					.streetLine0("Should not use 'streetLine'"),
					.streetLine1("Should not use 'streetLine'"),
					.postalCodeNumber(123),
					.city("Tokyo"),
				]
			)
		)
	}

	func test_json_coding_persona() throws {
		let personaData = try withDependencies {
			$0.uuid = .incrementing
		} operation: {
			try PersonaData(
				name: .init(value: .init(
					given: "Satoshi",
					middle: "Creator of Bitcoin",
					family: "Nakamoto", variant: .eastern
				)),
				dateOfBirth: .init(value: .init(year: 2009, month: 1, day: 3)),
				companyName: .init(value: .init(name: "Bitcoin")),
				emailAddresses: .init(collection: [
					.init(value: .init(validating: "satoshi@nakamoto.bitcoin")),
					.init(value: .init(validating: "be.your@own.bank")),
				]),
				phoneNumbers: .init(collection: [
					.init(value: .init(number: "21000000")),
					.init(value: .init(number: "123456789")),
				]),
				urls: .init(collection: [
					.init(value: .init(validating: "bitcoin.org")),
					.init(value: .init(validating: "https://github.com/bitcoin-core/secp256k1")),
				]),
				postalAddresses: .init(collection: [
					.init(value: .init(validating: [
						.postalCodeNumber(21_000_000),
						.prefecture("SHA256"), .county("Hashtown"),
						.furtherDivisionsLine0("Sound money street"),
						.furtherDivisionsLine1(""),
						.country(.japan),
					])),
					.init(value: .init(validating: [
						.streetLine0("Copthall House"),
						.streetLine1("King street"),
						.city("Newcastle-under-Lyme"),
						.county("Newcastle"),
						.postcodeString("ST5 1UE"),
						.country(.unitedKingdom),
					])),
				]),
				creditCards: .init(collection: [
					.init(value: .init(
						expiry: .init(year: 2142, month: 12),
						holder: "Satoshi Nakamoto",
						number: "0000 0000 2100 0000",
						cvc: 512
					)),
				])
			)
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
							"discriminator": "postalCodeNumber",
							"value": 21_000_000,
						],
						[
							"discriminator": "prefecture",
							"value": "SHA256",
						],
						[
							"discriminator": "county",
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
							"discriminator": "country",
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
							"discriminator": "city",
							"value": "Newcastle-under-Lyme",
						],
						[
							"discriminator": "county",
							"value": "Newcastle",
						],
						[
							"discriminator": "postcodeString",
							"value": "ST5 1UE",
						],
						[
							"discriminator": "country",
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
		try! self.init(value: .init(validating: value))
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
		try! self.init(validating: value)
	}
}

// MARK: - PersonaData.CollectionOfIdentifiedEntries + ExpressibleByArrayLiteral
extension PersonaData.CollectionOfIdentifiedEntries: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: PersonaData.IdentifiedEntry<Value>...) {
		try! self.init(collection: .init(uncheckedUniqueElements: elements))
	}
}
