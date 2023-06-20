import CasePaths
import Prelude

// MARK: - PersonaDataEntry
public enum PersonaDataEntry: Sendable, Hashable, Codable, BasePersonaFieldValueProtocol {
	case name(Name)
	case dateOfBirth(DateOfBirth)
	case emailAddress(EmailAddress)
	case postalAddress(PostalAddress)
	case phoneNumber(PhoneNumber)
	case creditCard(CreditCard)
}

extension PersonaDataEntry {
	private enum CodingKeys: String, CodingKey {
		case discriminator
		case name, dateOfBirth, postalAddress, emailAddress, phoneNumber, creditCard
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(discriminator, forKey: .discriminator)
		switch self {
		case let .name(value):
			try container.encode(value, forKey: .name)
		case let .dateOfBirth(value):
			try container.encode(value, forKey: .dateOfBirth)
		case let .emailAddress(value):
			try container.encode(value, forKey: .emailAddress)
		case let .postalAddress(value):
			try container.encode(value, forKey: .postalAddress)
		case let .phoneNumber(value):
			try container.encode(value, forKey: .phoneNumber)
		case let .creditCard(value):
			try container.encode(value, forKey: .creditCard)
		}
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try container.decode(PersonaFieldKind.self, forKey: .discriminator)
		switch discriminator {
		case .name:
			self = try .name(container.decode(Name.self, forKey: .name))
		case .dateOfBirth:
			self = try .dateOfBirth(container.decode(DateOfBirth.self, forKey: .dateOfBirth))
		case .emailAddress:
			self = try .emailAddress(container.decode(EmailAddress.self, forKey: .emailAddress))
		case .postalAddress:
			self = try .postalAddress(container.decode(PostalAddress.self, forKey: .postalAddress))
		case .phoneNumber:
			self = try .phoneNumber(container.decode(PhoneNumber.self, forKey: .phoneNumber))
		case .creditCard:
			self = try .creditCard(container.decode(CreditCard.self, forKey: .creditCard))
		}
	}
}

extension PersonaDataEntry {
	public var discriminator: PersonaFieldKind {
		switch self {
		case .name: return .name
		case .emailAddress: return .emailAddress
		case .phoneNumber: return .phoneNumber
		case .dateOfBirth: return .dateOfBirth
		case .postalAddress: return .postalAddress
		case .creditCard: return .creditCard
		}
	}

	public func embed() -> PersonaDataEntry {
		switch self {
		case let .name(value): return value.embed()
		case let .emailAddress(value): return value.embed()
		case let .postalAddress(value): return value.embed()
		case let .phoneNumber(value): return value.embed()
		case let .dateOfBirth(value): return value.embed()
		case let .creditCard(value): return value.embed()
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
	case creditCard
}

public typealias PersonaDataEntryID = UUID

// MARK: - PersonaDataEntryOfKind
/// * Names
/// * Postal Addresses
/// * Email Addresses
/// * URL Addresses
/// * Telephone numbers
/// * Birthday
public struct PersonaDataEntryOfKind<Value>: Sendable, Hashable, Codable, Identifiable where Value: Sendable & Hashable & Codable & BasePersonaFieldValueProtocol {
	public typealias ID = PersonaDataEntryID
	public let id: ID
	public var value: Value

	public init(
		id: ID? = nil,
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
