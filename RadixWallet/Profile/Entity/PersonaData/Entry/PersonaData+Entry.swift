// MARK: - PersonaData.Entry
extension PersonaData {
	public enum Entry: Sendable, Hashable, Codable, BasePersonaDataEntryProtocol, CustomStringConvertible {
		case name(Name)
		case dateOfBirth(DateOfBirth)
		case companyName(CompanyName)

		case emailAddress(EmailAddress)
		case phoneNumber(PhoneNumber)
		case url(AssociatedURL)
		case postalAddress(PostalAddress)
		case creditCard(CreditCard)
	}
}

extension PersonaData.Entry {
	public var discriminator: PersonaData.Entry.Kind {
		switch self {
		case .name: .fullName
		case .dateOfBirth: .dateOfBirth
		case .companyName: .companyName

		case .emailAddress: .emailAddress
		case .phoneNumber: .phoneNumber
		case .url: .url
		case .postalAddress: .postalAddress
		case .creditCard: .creditCard
		}
	}

	public func embed() -> PersonaData.Entry {
		switch self {
		case let .name(value): value.embed()
		case let .dateOfBirth(value): value.embed()
		case let .companyName(value): value.embed()

		case let .emailAddress(value): value.embed()
		case let .phoneNumber(value): value.embed()
		case let .url(value): value.embed()
		case let .postalAddress(value): value.embed()
		case let .creditCard(value): value.embed()
		}
	}
}

// FIXME: This could also be a requirement in BasePersonaDataEntryProtocol
extension PersonaData.Entry {
	public var description: String {
		switch self {
		case let .name(name):
			name.description
		case let .dateOfBirth(dateOfBirth):
			dateOfBirth.description
		case let .companyName(companyName):
			companyName.description
		case let .emailAddress(emailAddress):
			emailAddress.description
		case let .phoneNumber(phoneNumber):
			phoneNumber.description
		case let .url(associatedURL):
			associatedURL.description
		case let .postalAddress(postalAddress):
			postalAddress.description
		case let .creditCard(creditCard):
			creditCard.description
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
