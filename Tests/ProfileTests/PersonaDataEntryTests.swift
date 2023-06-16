import CasePaths
import Cryptography
import EngineToolkit
@testable import Profile
import RadixConnectModels
import SharedTestingModels
import SwiftUI
import TestingPrelude

// MARK: - DuplicateValuesFound
struct DuplicateValuesFound: Swift.Error {}

// MARK: - DuplicateIDOfValueFound
struct DuplicateIDOfValueFound: Swift.Error {}

// MARK: - PersonaFieldCollectionValueWithIDNotFound
struct PersonaFieldCollectionValueWithIDNotFound: Swift.Error {
	let id: UUID
}

// MARK: - Persona
public struct Persona: Sendable, Hashable, Codable {
	public let label: String
	public let personaData: PersonaData

	public struct PersonaData: Sendable, Hashable, Codable {
		public typealias Name = PersonaDataEntryOfKind<PersonaDataEntry.Name>

		public struct EntryCollectionOf<Value: Sendable & Hashable & Codable & BasePersonaFieldValueProtocol>: Sendable, Hashable, Codable {
			public private(set) var collection: IdentifiedArrayOf<PersonaDataEntryOfKind<Value>>
			public init(collection: IdentifiedArrayOf<PersonaDataEntryOfKind<Value>> = .init()) throws {
				guard Set(collection.map(\.value)).count == collection.count else {
					throw DuplicateValuesFound()
				}
				self.collection = collection
			}

			public mutating func add(_ field: PersonaDataEntryOfKind<Value>) throws {
				guard !contains(where: { $0.value == field.value }) else {
					throw DuplicateValuesFound()
				}
				let (wasInserted, _) = self.collection.append(field)
				guard wasInserted else {
					throw DuplicateIDOfValueFound()
				}
			}

			public mutating func update(_ updated: PersonaDataEntryOfKind<Value>) throws {
				guard contains(where: { $0.id == updated.id }) else {
					throw PersonaFieldCollectionValueWithIDNotFound(id: updated.id)
				}
				self.collection[id: updated.id] = updated
			}
		}

		public typealias EmailAddresses = EntryCollectionOf<PersonaDataEntry.EmailAddress>
		public typealias PostalAddresses = EntryCollectionOf<PersonaDataEntry.PostalAddress>

		public var name: Name?
		public var emailAddresses: EmailAddresses
		public var postalAddresses: PostalAddresses

		public init(
			name: Name? = nil,
			emailAddresses: EmailAddresses = [],
			postalAddresses: PostalAddresses = []
		) {
			self.name = name
			self.emailAddresses = emailAddresses
			self.postalAddresses = postalAddresses
		}
	}
}

// MARK: - Persona.PersonaData.EntryCollectionOf + RandomAccessCollection
extension Persona.PersonaData.EntryCollectionOf: RandomAccessCollection {
	public typealias Element = PersonaDataEntryOfKind<Value>

	public typealias Index = IdentifiedArrayOf<PersonaDataEntryOfKind<Value>>.Index

	public typealias SubSequence = IdentifiedArrayOf<PersonaDataEntryOfKind<Value>>.SubSequence

	public typealias Indices = IdentifiedArrayOf<PersonaDataEntryOfKind<Value>>.Indices

	public var startIndex: Index {
		collection.startIndex
	}

	public var indices: Indices {
		collection.indices
	}

	public var endIndex: Index {
		collection.endIndex
	}

	public func formIndex(after index: inout Index) {
		collection.formIndex(after: &index)
	}

	public func formIndex(before index: inout Index) {
		collection.formIndex(before: &index)
	}

	public subscript(bounds: Range<Index>) -> SubSequence {
		collection[bounds]
	}

	public subscript(position: Index) -> Element {
		collection[position]
	}
}

extension Persona.PersonaData {
	public var all: OrderedSet<PersonaField> {
		.init(uncheckedUniqueElements: [
			name?.embed(),
		].compactMap { $0 })
	}
}

extension Persona {
	public var fields: OrderedSet<PersonaField> {
		personaData.all
	}
}

// MARK: - BasePersonaFieldValueProtocol
public protocol BasePersonaFieldValueProtocol {
	func embed() -> PersonaDataEntry
}

// MARK: - PersonaFieldValueProtocol
public protocol PersonaFieldValueProtocol: BasePersonaFieldValueProtocol {
	static var casePath: CasePath<PersonaDataEntry, Self> { get }
	static var kind: PersonaFieldKind { get }
}

public typealias PersonaField = PersonaDataEntryOfKind<PersonaDataEntry>

extension PersonaDataEntryOfKind {
	public func embed() -> PersonaField {
		.init(id: id, value: value.embed())
	}
}

// MARK: - PersonaFieldKind
public enum PersonaFieldKind: String, Sendable, Hashable, Codable {
	case name
	case emailAddress
	case postalAddress
}

// MARK: - PersonaDataEntry
public enum PersonaDataEntry: Sendable, Hashable, Codable, BasePersonaFieldValueProtocol {
	public var discriminator: PersonaFieldKind {
		switch self {
		case .name: return .name
		case .emailAddress: return .emailAddress
		case .postalAddress: return .postalAddress
		}
	}

	public func embed() -> PersonaDataEntry {
		switch self {
		case let .name(value): return value.embed()
		case let .emailAddress(value): return value.embed()
		case let .postalAddress(value): return value.embed()
		}
	}

	public struct Name: Sendable, Hashable, Codable, PersonaFieldValueProtocol {
		public static var casePath: CasePath<PersonaDataEntry, Self> = /PersonaDataEntry.name
		public static var kind = PersonaFieldKind.name

		/// First/Given/Fore-name, .e.g. `"John"`
		public let given: String

		/// Middle name, e.g. `"Fitzgerald"`
		public let middle: String?

		/// Last/Family/Sur-name, .e.g. `"Kennedey"`
		public let family: String

		public init(given: String, middle: String? = nil, family: String, variant: Variant) {
			self.given = given
			self.middle = middle
			self.family = family
			self.variant = variant
		}

		public enum Variant: String, Sendable, Hashable, Codable {
			/// order: `given middle family`
			case western

			/// order: `family (middle) given`
			case eastern
		}

		public let variant: Variant
	}

	public struct EmailAddress: Sendable, Hashable, Codable, PersonaFieldValueProtocol {
		public static var casePath: CasePath<PersonaDataEntry, Self> = /PersonaDataEntry.emailAddress
		public static var kind = PersonaFieldKind.emailAddress

		public let email: String

		public init(validating email: String) throws {
			guard email.isEmailAddress else {
				throw InvalidEmailAddress(invalid: email)
			}
			self.email = email
		}

		struct InvalidEmailAddress: Swift.Error {
			let invalid: String
		}
	}

	case name(Name)
	case emailAddress(EmailAddress)
	case postalAddress(PostalAddress)
}

// MARK: - PersonaDataEntryOfKind
/// * Names
/// * Postal Addresses
/// * Email Addresses
/// * URL Addresses
/// * Telephone numbers
/// * Birthday
public struct PersonaDataEntryOfKind<Value>: Sendable, Hashable, Codable, Identifiable where Value: Sendable & Hashable & Codable & BasePersonaFieldValueProtocol {
	public let id: UUID
	public var value: Value

	public init(
		id: UUID? = nil,
		value: Value
	) {
		@Dependency(\.uuid) var uuid
		self.id = id ?? uuid()
		self.value = value
	}
}

extension PersonaFieldValueProtocol {
	public var kind: PersonaFieldKind { Self.kind }
	public var casePath: CasePath<PersonaDataEntry, Self> { Self.casePath }

	public func embed() -> PersonaDataEntry {
		casePath.embed(self)
	}

	public static func extract(from fieldValue: PersonaDataEntry) -> Self? {
		casePath.extract(from: fieldValue)
	}
}

extension PersonaDataEntry {
	public func extract<F>(_ type: F.Type = F.self) -> F? where F: PersonaFieldValueProtocol {
		F.extract(from: self)
	}

	public func extract<F>(as _: F.Type = F.self) throws -> F where F: PersonaFieldValueProtocol {
		guard let extracted = extract(F.self) else {
			throw IncorrectPersonaFieldType(expectedKind: F.kind, actualKind: discriminator)
		}
		return extracted
	}
}

// MARK: - IncorrectPersonaFieldType
public struct IncorrectPersonaFieldType: Swift.Error {
	public let expectedKind: PersonaFieldKind
	public let actualKind: PersonaFieldKind
}

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
						.postalCodeNumber(11129),
						.city("Stockholm"),
						.streetLine0("Västerlånggatan 31"),
						.streetLine1(""),
						.country(.sweden),
					]]
				)
			)

			let addresses = try dappRequest(values: \.postalAddresses, from: persona)
			XCTAssertEqual(addresses[0], [
				.postalCodeNumber(11129),
				.city("Stockholm"),
				.streetLine0("Västerlånggatan 31"),
				.streetLine1(""),
				.country(.sweden),
			])
		}
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
