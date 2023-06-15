import CasePaths
import Cryptography
import EngineToolkit
@testable import Profile
import RadixConnectModels
import SharedTestingModels
import TestingPrelude

// MARK: - Persona
public struct Persona: Sendable, Hashable, Codable {
	public let label: String
	public let personaData: PersonaData

	public var fields: OrderedSet<PersonaField> {
		personaData.all
	}

	public struct PersonaData: Sendable, Hashable, Codable {
		public let name: PersonaFieldOfKind<PersonaFieldValue.Name>?

		public var all: OrderedSet<PersonaField> {
			.init(uncheckedUniqueElements: [
				name?.embed(),
			].compactMap { $0 })
		}
	}
}

// MARK: - BasePersonaFieldValueProtocol
public protocol BasePersonaFieldValueProtocol {
	func embed() -> PersonaFieldValue
}

// MARK: - PersonaFieldValueProtocol
public protocol PersonaFieldValueProtocol: BasePersonaFieldValueProtocol {
	static var casePath: CasePath<PersonaFieldValue, Self> { get }
	static var kind: PersonaFieldKind { get }
}

public typealias PersonaField = PersonaFieldOfKind<PersonaFieldValue>

extension PersonaFieldOfKind {
	public func embed() -> PersonaField {
		.init(id: id, value: value.embed())
	}
}

// MARK: - PersonaFieldKind
public enum PersonaFieldKind: Sendable, Hashable, Codable {
	case name
	case emailAddress
}

// MARK: - PersonaFieldValue
public enum PersonaFieldValue: Sendable, Hashable, Codable, BasePersonaFieldValueProtocol {
	public var discriminator: PersonaFieldKind {
		switch self {
		case .name: return .name
		case .emailAddress: return .emailAddress
		}
	}

	public func embed() -> PersonaFieldValue {
		switch self {
		case let .name(value): return value.embed()
		case let .emailAddress(value): return value.embed()
		}
	}

	public struct Name: Sendable, Hashable, Codable, PersonaFieldValueProtocol {
		public static var casePath: CasePath<PersonaFieldValue, Self> = /PersonaFieldValue.name
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
		public static var casePath: CasePath<PersonaFieldValue, Self> = /PersonaFieldValue.emailAddress
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
}

// MARK: - PersonaFieldOfKind
/// * Names
/// * Postal Addresses
/// * Email Addresses
/// * URL Addresses
/// * Telephone numbers
/// * Birthday
public struct PersonaFieldOfKind<Value>: Sendable, Hashable, Codable where Value: Sendable & Hashable & Codable & BasePersonaFieldValueProtocol {
	public let id: UUID
	public let value: Value

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
	public var casePath: CasePath<PersonaFieldValue, Self> { Self.casePath }

	public func embed() -> PersonaFieldValue {
		casePath.embed(self)
	}

	public static func extract(from fieldValue: PersonaFieldValue) -> Self? {
		casePath.extract(from: fieldValue)
	}
}

extension PersonaFieldValue {
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

extension PersonaFieldValue.Name {
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

		let aName = try dappRequest(read: PersonaFieldValue.Name.self, from: persona)
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
		let aName = try dappRequest(read: PersonaFieldValue.Name.self, from: persona)
		XCTAssertEqual(aName.value.valueForDapp, "Park Chan-wook")
	}

	func dappRequest<Kind: PersonaFieldValueProtocol>(
		read kind: Kind.Type = Kind.self,
		from persona: Persona
	) throws -> PersonaFieldOfKind<Kind> {
		guard let field = dappRequest(read: kind, amongst: persona.fields) else {
			throw NoSuchField()
		}
		return field
	}

	func dappRequest<Kind: PersonaFieldValueProtocol>(
		read kind: Kind.Type = Kind.self,
		amongst fields: OrderedSet<PersonaField>
	) -> PersonaFieldOfKind<Kind>? {
		fields.compactMap { (field: PersonaField) -> PersonaFieldOfKind<Kind>? in
			guard let value = field.value.extract(Kind.self) else {
				return nil
			}
			return PersonaFieldOfKind<Kind>(id: field.id, value: value)
		}
		.first
	}
}

// MARK: - NoSuchField
struct NoSuchField: Error {}
