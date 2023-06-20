import CasePaths
import Prelude

// MARK: - PersonaData.Entry
extension PersonaData {
	public enum Entry: Sendable, Hashable, Codable, BasePersonaDataEntryProtocol {
		case name(Name)
		case dateOfBirth(DateOfBirth)
		case emailAddress(EmailAddress)
		case postalAddress(PostalAddress)
		case phoneNumber(PhoneNumber)
		case creditCard(CreditCard)
	}
}

extension PersonaData.Entry {
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
		let discriminator = try container.decode(PersonaData.Entry.Kind.self, forKey: .discriminator)
		switch discriminator {
		case .name:
			self = try .name(container.decode(PersonaData.Name.self, forKey: .name))
		case .dateOfBirth:
			self = try .dateOfBirth(container.decode(PersonaData.DateOfBirth.self, forKey: .dateOfBirth))
		case .emailAddress:
			self = try .emailAddress(container.decode(PersonaData.EmailAddress.self, forKey: .emailAddress))
		case .postalAddress:
			self = try .postalAddress(container.decode(PersonaData.PostalAddress.self, forKey: .postalAddress))
		case .phoneNumber:
			self = try .phoneNumber(container.decode(PersonaData.PhoneNumber.self, forKey: .phoneNumber))
		case .creditCard:
			self = try .creditCard(container.decode(PersonaData.CreditCard.self, forKey: .creditCard))
		}
	}
}

extension PersonaData.Entry {
	public var discriminator: PersonaData.Entry.Kind {
		switch self {
		case .name: return .name
		case .emailAddress: return .emailAddress
		case .phoneNumber: return .phoneNumber
		case .dateOfBirth: return .dateOfBirth
		case .postalAddress: return .postalAddress
		case .creditCard: return .creditCard
		}
	}

	public func embed() -> PersonaData.Entry {
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

// MARK: - BasePersonaDataEntryProtocol
public protocol BasePersonaDataEntryProtocol {
	func embed() -> PersonaData.Entry
}

// MARK: - PersonaDataEntryProtocol
public protocol PersonaDataEntryProtocol: BasePersonaDataEntryProtocol {
	static var casePath: CasePath<PersonaData.Entry, Self> { get }
	static var kind: PersonaData.Entry.Kind { get }
}

// MARK: - PersonaData.Entry.Kind
extension PersonaData.Entry {
	public enum Kind: String, Sendable, Hashable, Codable {
		case name
		case emailAddress
		case dateOfBirth
		case postalAddress
		case phoneNumber
		case creditCard
	}
}

public typealias PersonaDataEntryID = UUID

public typealias AnyIdentifiedPersonaEntry = PersonaData.IdentifiedEntry<PersonaData.Entry>

extension PersonaData.IdentifiedEntry {
	public func embed() -> AnyIdentifiedPersonaEntry {
		.init(id: id, value: value.embed())
	}
}

// MARK: - PersonaData.IdentifiedEntry
extension PersonaData {
	public struct IdentifiedEntry<Kind>: Sendable, Hashable, Codable, Identifiable where Kind: Sendable & Hashable & Codable & BasePersonaDataEntryProtocol {
		public typealias ID = PersonaDataEntryID
		public let id: ID
		public var value: Kind

		public init(
			id: ID? = nil,
			value: Kind
		) {
			@Dependency(\.uuid) var uuid
			self.id = id ?? uuid()
			self.value = value
		}
	}
}

extension PersonaDataEntryProtocol {
	public var kind: PersonaData.Entry.Kind { Self.kind }
	public var casePath: CasePath<PersonaData.Entry, Self> { Self.casePath }

	public func embed() -> PersonaData.Entry {
		casePath.embed(self)
	}

	public static func extract(from fieldValue: PersonaData.Entry) -> Self? {
		casePath.extract(from: fieldValue)
	}
}

extension PersonaData.Entry {
	public func extract<F>(_ type: F.Type = F.self) -> F? where F: PersonaDataEntryProtocol {
		F.extract(from: self)
	}

	public func extract<F>(as _: F.Type = F.self) throws -> F where F: PersonaDataEntryProtocol {
		guard let extracted = extract(F.self) else {
			throw IncorrectPersonaFieldType(expectedKind: F.kind, actualKind: discriminator)
		}
		return extracted
	}
}

// MARK: - IncorrectPersonaFieldType
public struct IncorrectPersonaFieldType: Swift.Error {
	public let expectedKind: PersonaData.Entry.Kind
	public let actualKind: PersonaData.Entry.Kind
}
