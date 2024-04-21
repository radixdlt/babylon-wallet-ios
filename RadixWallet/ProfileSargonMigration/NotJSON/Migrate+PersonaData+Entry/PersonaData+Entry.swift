import Sargon
import SargonUniFFI

// MARK: - PersonaDataEntryName + BasePersonaDataEntryProtocol
extension PersonaDataEntryName: BasePersonaDataEntryProtocol {
	public func embed() -> PersonaData.Entry {
		.name(self)
	}
}

extension PersonaDataIdentifiedName {
	public func embed() -> AnyIdentifiedPersonaEntry {
		.init(id: self.id, value: self.value.embed())
	}
}

// MARK: - PersonaDataEntryEmailAddress + BasePersonaDataEntryProtocol
extension PersonaDataEntryEmailAddress: BasePersonaDataEntryProtocol {
	public func embed() -> PersonaData.Entry {
		.emailAddress(self)
	}
}

extension PersonaDataIdentifiedEmailAddress {
	public func embed() -> AnyIdentifiedPersonaEntry {
		.init(id: self.id, value: self.value.embed())
	}
}

// MARK: - PersonaDataEntryPhoneNumber + BasePersonaDataEntryProtocol
extension PersonaDataEntryPhoneNumber: BasePersonaDataEntryProtocol {
	public func embed() -> PersonaData.Entry {
		.phoneNumber(self)
	}
}

extension PersonaDataIdentifiedPhoneNumber {
	public func embed() -> AnyIdentifiedPersonaEntry {
		.init(id: self.id, value: self.value.embed())
	}
}

// MARK: - PersonaData.Entry
extension PersonaData {
	public enum Entry: Sendable, Hashable, Codable, BasePersonaDataEntryProtocol, CustomStringConvertible {
		case name(PersonaDataEntryName)
		case emailAddress(PersonaDataEntryEmailAddress)
		case phoneNumber(PersonaDataEntryPhoneNumber)
	}
}

extension PersonaData.Entry {
	public var discriminator: PersonaData.Entry.Kind {
		switch self {
		case .name: .fullName
		case .emailAddress: .emailAddress
		case .phoneNumber: .phoneNumber
		}
	}

	public func embed() -> PersonaData.Entry {
		switch self {
		case let .name(value): value.embed()
		case let .emailAddress(value): value.embed()
		case let .phoneNumber(value): value.embed()
		}
	}
}

// FIXME: This could also be a requirement in BasePersonaDataEntryProtocol
extension PersonaData.Entry {
	public var description: String {
		switch self {
		case let .name(name):
			name.description
		case let .emailAddress(emailAddress):
			emailAddress.email.description
		case let .phoneNumber(phoneNumber):
			phoneNumber.number.description
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
