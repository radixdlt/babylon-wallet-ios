import Prelude

// MARK: - PersonaData
public struct PersonaData: Sendable, Hashable, Codable {
	public typealias IdentifiedName = IdentifiedEntry<Name>
	public typealias IdentifiedDateOfBirth = IdentifiedEntry<DateOfBirth>
	public typealias IdentifiedCompanyName = IdentifiedEntry<CompanyName>

	public typealias IdentifiedEmailAddresses = CollectionOfIdentifiedEntries<EmailAddress>
	public typealias IdentifiedPostalAddresses = CollectionOfIdentifiedEntries<PostalAddress>
	public typealias IdentifiedPhoneNumbers = CollectionOfIdentifiedEntries<PhoneNumber>
	public typealias IdentifiedCreditCards = CollectionOfIdentifiedEntries<CreditCard>

	public var name: IdentifiedName?
	public var dateOfBirth: IdentifiedDateOfBirth?
	public var companyName: IdentifiedCompanyName?
	public var emailAddresses: IdentifiedEmailAddresses
	public var postalAddresses: IdentifiedPostalAddresses
	public var phoneNumbers: IdentifiedPhoneNumbers
	public var creditCards: IdentifiedCreditCards

	public init(
		name: IdentifiedName? = nil,
		dateOfBirth: IdentifiedDateOfBirth? = nil,
		companyName: IdentifiedCompanyName? = nil,
		emailAddresses: IdentifiedEmailAddresses = .init(),
		postalAddresses: IdentifiedPostalAddresses = .init(),
		phoneNumbers: IdentifiedPhoneNumbers = .init(),
		creditCards: IdentifiedCreditCards = .init()
	) {
		self.name = name
		self.dateOfBirth = dateOfBirth
		self.companyName = companyName
		self.emailAddresses = emailAddresses
		self.postalAddresses = postalAddresses
		self.phoneNumbers = phoneNumbers
		self.creditCards = creditCards
	}
}

extension PersonaData {
	public var entries: [AnyIdentifiedPersonaEntry] {
		var sequence: [AnyIdentifiedPersonaEntry?] = []
		sequence.append(name?.embed())
		sequence.append(dateOfBirth?.embed())
		sequence.append(companyName?.embed())
		sequence.append(contentsOf: emailAddresses.map { $0.embed() })
		sequence.append(contentsOf: postalAddresses.map { $0.embed() })
		sequence.append(contentsOf: phoneNumbers.map { $0.embed() })
		sequence.append(contentsOf: creditCards.map { $0.embed() })
		return sequence.compactMap { $0 }
	}
}
