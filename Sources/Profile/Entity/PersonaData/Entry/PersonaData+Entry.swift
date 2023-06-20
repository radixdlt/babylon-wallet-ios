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
	let id: PersonaDataEntryID
}

public typealias PersonaDataEntryID = UUID

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
