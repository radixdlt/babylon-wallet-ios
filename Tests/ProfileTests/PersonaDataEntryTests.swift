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
		let persona = withDependencies {
			$0.uuid = .incrementing
		} operation: {
			Persona(
				label: "Mr President",
				personaData: .init(
					name: .init(
						value: .init(
							given: "John",
							middle: "Fitzgerald",
							family: "Kennedy",
							variant: .western
						)
					)
				)
			)
		}

		let aName = try dappRequest(value: \.name, from: persona)
		XCTAssertEqual(aName.value.valueForDapp, "John Fitzgerald Kennedy")
	}

	func test_name_eastern() throws {
		let persona = withDependencies {
			$0.uuid = .incrementing
		} operation: {
			Persona(
				label: "Best Director",
				personaData: .init(
					name: .init(
						value: .init(
							given: "Chan-wook",
							family: "Park",
							variant: .eastern
						)
					)
				)
			)
		}
		let aName = try dappRequest(value: \.name, from: persona)
		XCTAssertEqual(aName.value.valueForDapp, "Park Chan-wook")
	}

	func test_email_addresses() throws {
		let persona = withDependencies {
			$0.uuid = .incrementing
		} operation: {
			Persona(
				label: "Dr Email",
				personaData: .init(
					emailAddresses: [
						.init(value: "hi@rdx.works"),
						.init(value: "bye@rdx.works"),
					]
				)
			)
		}

		let emails = try dappRequest(values: \.emailAddresses, from: persona)
		XCTAssertEqual(emails.map(\.value), ["hi@rdx.works", "bye@rdx.works"])
	}

	func test_assert_personaData_fieldCollectionOf_cannot_contain_duplicated_values() {
		XCTAssertThrowsError(
			try Persona.PersonaData.EmailAddresses(
				collection: [
					.init(id: .init(uuidString: "BBBBBBBB-0000-1111-2222-BBBBBBBBBBBB"), value: "hi@rdx.works"),
					.init(id: .init(uuidString: "AAAAAAAA-9999-8888-7777-AAAAAAAAAAAA"), value: "hi@rdx.works"), // same value cannot be used twice, even though UUID differs!
				]
			)
		)
	}

	func test_assert_personaData_fieldCollectionOf_cannot_add_duplicate_value() throws {
		var fieldCollection = try Persona.PersonaData.EmailAddresses(
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
		var fieldCollection = try Persona.PersonaData.EmailAddresses(
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
		var fieldCollection = try Persona.PersonaData.EmailAddresses(
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
		var email = Persona.PersonaData.EmailAddresses.Element(
			id: .init(uuidString: "BBBBBBBB-0000-1111-2222-BBBBBBBBBBBB"),
			value: "hi@rdx.works"
		)
		var fieldCollection = try Persona.PersonaData.EmailAddresses(
			collection: [
				email,
			]
		)
		email.value = "bye@rdx.works"
		XCTAssertNoThrow(try fieldCollection.update(email))
		XCTAssertEqual(fieldCollection[0].value, "bye@rdx.works")
	}

	func test_assert_update_unknown_id_throws() throws {
		var fieldCollection = try Persona.PersonaData.EmailAddresses(
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
			let persona = Persona(
				label: "Olof Palme",
				personaData: .init(
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
			)

			let addresses = try dappRequest(values: \.postalAddresses, from: persona)
			XCTAssertEqual(addresses[0], [
				.streetLine0("Västerlånggatan 31"),
				.streetLine1(""),
				.postalCodeNumber(11129), .city("Stockholm"),
				.country(.sweden),
			])
		}
	}

	func test_multiple_postalAddresses_multiple() throws {
		let persona = withDependencies {
			$0.uuid = .incrementing
		} operation: {
			Persona(
				label: "Fake",
				personaData: .init(
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
			)
		}

		let addresses = try dappRequest(values: \.postalAddresses, from: persona)
		XCTAssertEqual(addresses.compactMap(\.value.country), [.sweden, .sweden, .france, .unitedKingdom])
	}

	func test_json_coding_persona_and_cap21() throws {
		let persona = try withDependencies {
			$0.uuid = .incrementing
		} operation: {
			try Persona(
				label: "Stadsministern",
				personaData: .init(
					name: .init(
						value: .init(
							given: "Olof",
							family: "Palme",
							variant: .western
						)
					),
					dateOfBirth: .init(value: .init(year: 1927, month: 01, day: 30)),
					emailAddresses: [
						"palme@stadsminister.se",
						"olof@boss.se",
					],
					postalAddresses: [
						[
							.streetLine0("Västerlånggatan 31"),
							.streetLine1(""),
							.postalCodeNumber(11129), .city("Stockholm"),
							.country(.sweden),
						],
						[
							.streetLine0("Strömgatan 18"),
							.streetLine1("Sagerska Huset"),
							.postalCodeNumber(11152), .city("Stockholm"),
							.country(.sweden),
						],
					],
					phoneNumbers: [
						.init(value: .init(number: "+468-1234567")),
						.init(value: .init(number: "+468-9876543")),
					]
				)
			)
		}

		let personaJSON: JSON = [
			"label": "Stadsministern",
			"personaData": [
				"name": [
					"id": "00000000-0000-0000-0000-000000000000",
					"value": [
						"family": "Palme",
						"given": "Olof",
						"variant": "western",
					],
				],
				"dateOfBirth": [
					"id": "00000000-0000-0000-0000-000000000001",
					"value": "1927-01-30T12:00:00Z",
				],
				"emailAddresses": [
					[
						"id": "00000000-0000-0000-0000-000000000002",
						"value": "palme@stadsminister.se",
					],
					[
						"id": "00000000-0000-0000-0000-000000000003",
						"value": "olof@boss.se",
					],
				],
				"postalAddresses": [
					[
						"id": "00000000-0000-0000-0000-000000000004",
						"value": [
							[
								"discriminator": "streetLine0",
								"value": "Västerlånggatan 31",
							],
							[
								"discriminator": "streetLine1",
								"value": "",
							],
							[
								"discriminator": "postalCodeNumber",
								"value": 11129,
							],
							[
								"discriminator": "city",
								"value": "Stockholm",
							],
							[
								"discriminator": "country",
								"value": "sweden",
							],
						],
					],
					[
						"id": "00000000-0000-0000-0000-000000000005",
						"value": [
							[
								"discriminator": "streetLine0",
								"value": "Strömgatan 18",
							],
							[
								"discriminator": "streetLine1",
								"value": "Sagerska Huset",
							],
							[
								"discriminator": "postalCodeNumber",
								"value": 11152,
							],
							[
								"discriminator": "city",
								"value": "Stockholm",
							],
							[
								"discriminator": "country",
								"value": "sweden",
							],
						],
					],
				],
				"phoneNumbers": [
					[
						"id": "00000000-0000-0000-0000-000000000006",
						"value": "+468-1234567",
					],
					[
						"id": "00000000-0000-0000-0000-000000000007",
						"value": "+468-9876543",
					],
				],
			],
		]

		try XCTAssertJSONEncoding(
			persona,
			personaJSON
		)

		try XCTAssertJSONDecoding(
			personaJSON,
			persona
		)
	}
}

// MARK: - PersonaDataEntryOfKind + ExpressibleByStringLiteral, ExpressibleByUnicodeScalarLiteral, ExpressibleByExtendedGraphemeClusterLiteral
extension PersonaDataEntryOfKind<PersonaDataEntry.EmailAddress>: ExpressibleByStringLiteral, ExpressibleByUnicodeScalarLiteral, ExpressibleByExtendedGraphemeClusterLiteral {
	public init(stringLiteral value: String) {
		try! self.init(value: .init(validating: value))
	}
}

// MARK: - PersonaDataEntry.PostalAddress + ExpressibleByArrayLiteral
extension PersonaDataEntry.PostalAddress: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: PersonaDataEntry.PostalAddress.Field...) {
		try! self.init(validating: .init(uncheckedUniqueElements: elements))
	}
}

// MARK: - PersonaDataEntryOfKind + ExpressibleByArrayLiteral
extension PersonaDataEntryOfKind<PersonaDataEntry.PostalAddress>: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: PersonaDataEntry.PostalAddress.Field...) {
		try! self.init(value: .init(validating: .init(uncheckedUniqueElements: elements)))
	}
}

private extension PersonaFieldTests {
	func dappRequest<Kind: PersonaFieldValueProtocol>(
		values keyPath: KeyPath<Persona.PersonaData, Persona.PersonaData.EntryCollectionOf<Kind>>,
		from persona: Persona
	) throws -> Persona.PersonaData.EntryCollectionOf<Kind> {
		persona.personaData[keyPath: keyPath]
	}

	func dappRequest<Kind: PersonaFieldValueProtocol>(
		value keyPath: KeyPath<Persona.PersonaData, PersonaDataEntryOfKind<Kind>?>,
		from persona: Persona
	) throws -> PersonaDataEntryOfKind<Kind> {
		guard let field = persona.personaData[keyPath: keyPath] else {
			throw NoSuchField()
		}
		return field
	}
}

// MARK: - NoSuchField
struct NoSuchField: Error {}

extension PersonaDataEntry.Name {
	public var valueForDapp: String {
		let components: [String?] = {
			switch variant {
			case .western: return [given, middle, family]
			case .eastern: return [family, middle, given]
			}
		}()
		return components.compactMap { $0 }.joined(separator: " ")
	}
}

// MARK: - PersonaDataEntry.EmailAddress + ExpressibleByStringLiteral
extension PersonaDataEntry.EmailAddress: ExpressibleByStringLiteral {
	public init(stringLiteral value: String) {
		try! self.init(validating: value)
	}
}

// MARK: - Persona.PersonaData.EntryCollectionOf + ExpressibleByArrayLiteral
extension Persona.PersonaData.EntryCollectionOf: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: PersonaDataEntryOfKind<Value>...) {
		try! self.init(collection: .init(uncheckedUniqueElements: elements))
	}
}
