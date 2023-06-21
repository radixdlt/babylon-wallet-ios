import Prelude

// MARK: - PersonaData
public struct PersonaData: Sendable, Hashable, Codable {
	public typealias IdentifiedName = IdentifiedEntry<Name>
	public typealias IdentifiedDateOfBirth = IdentifiedEntry<DateOfBirth>
	public typealias IdentifiedCompanyName = IdentifiedEntry<CompanyName>

	public typealias IdentifiedEmailAddresses = CollectionOfIdentifiedEntries<EmailAddress>
	public typealias IdentifiedPhoneNumbers = CollectionOfIdentifiedEntries<PhoneNumber>
	public typealias IdentifiedURLs = CollectionOfIdentifiedEntries<AssociatedURL>
	public typealias IdentifiedPostalAddresses = CollectionOfIdentifiedEntries<PostalAddress>
	public typealias IdentifiedCreditCards = CollectionOfIdentifiedEntries<CreditCard>

	public var name: IdentifiedName?
	public var dateOfBirth: IdentifiedDateOfBirth?
	public var companyName: IdentifiedCompanyName?

	public var emailAddresses: IdentifiedEmailAddresses
	public var phoneNumbers: IdentifiedPhoneNumbers
	public var urls: IdentifiedURLs
	public var postalAddresses: IdentifiedPostalAddresses
	public var creditCards: IdentifiedCreditCards

	public init(
		name: IdentifiedName? = nil,
		dateOfBirth: IdentifiedDateOfBirth? = nil,
		companyName: IdentifiedCompanyName? = nil,
		emailAddresses: IdentifiedEmailAddresses = .init(),
		phoneNumbers: IdentifiedPhoneNumbers = .init(),
		urls: IdentifiedURLs = .init(),
		postalAddresses: IdentifiedPostalAddresses = .init(),
		creditCards: IdentifiedCreditCards = .init()
	) {
		// The only purpose of this switch is to make sure we get a compilation error when we add a new PersonaData.Entry kind, so
		// we do not forget to handle it here.
		switch PersonaData.Entry.Kind.name {
		case .name, .dateOfBirth, .companyName, .emailAddress, .phoneNumber, .url, .postalAddress, .creditCard: break
		}

		self.name = name
		self.dateOfBirth = dateOfBirth
		self.companyName = companyName

		self.emailAddresses = emailAddresses
		self.phoneNumbers = phoneNumbers
		self.urls = urls
		self.postalAddresses = postalAddresses
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
		sequence.append(contentsOf: phoneNumbers.map { $0.embed() })
		sequence.append(contentsOf: urls.map { $0.embed() })
		sequence.append(contentsOf: postalAddresses.map { $0.embed() })
		sequence.append(contentsOf: creditCards.map { $0.embed() })

		// The only purpose of this switch is to make sure we get a compilation error when we add a new PersonaData.Entry kind, so
		// we do not forget to handle it here.
		switch PersonaData.Entry.Kind.name {
		case .name, .dateOfBirth, .companyName, .emailAddress, .phoneNumber, .url, .postalAddress, .creditCard: break
		}

		return sequence.compactMap { $0 }
	}
}
