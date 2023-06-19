import CasePaths
import Prelude

// MARK: - PersonaDataEntry
public enum PersonaDataEntry: Sendable, Hashable, Codable, BasePersonaFieldValueProtocol {
	case name(Name)
	case phoneNumber(PhoneNumber)
	case emailAddress(EmailAddress)
	case dateOfBirth(DateOfBirth)
	case postalAddress(PostalAddress)
}

extension PersonaDataEntry {
	public var discriminator: PersonaFieldKind {
		switch self {
		case .name: return .name
		case .emailAddress: return .emailAddress
		case .phoneNumber: return .phoneNumber
		case .dateOfBirth: return .dateOfBirth
		case .postalAddress: return .postalAddress
		}
	}

	public func embed() -> PersonaDataEntry {
		switch self {
		case let .name(value): return value.embed()
		case let .emailAddress(value): return value.embed()
		case let .postalAddress(value): return value.embed()
		case let .phoneNumber(value): return value.embed()
		case let .dateOfBirth(value): return value.embed()
		}
	}
}

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
	case dateOfBirth
	case postalAddress
	case phoneNumber
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
