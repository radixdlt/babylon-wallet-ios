import Prelude

// MARK: - PersonaData
public struct PersonaData: Sendable, Hashable, Codable, CustomStringConvertible {
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
		switch PersonaData.Entry.Kind.fullName {
		case .fullName, .dateOfBirth, .companyName, .emailAddress, .phoneNumber, .url, .postalAddress, .creditCard: break
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
		switch PersonaData.Entry.Kind.fullName {
		case .fullName, .dateOfBirth, .companyName, .emailAddress, .phoneNumber, .url, .postalAddress, .creditCard: break
		}

		return sequence.compactMap { $0 }
	}

	public var description: String {
		entries.map(\.description).joined(separator: "\n")
	}
}

extension PersonaData {
	public static var previewValue: Self {
		@Dependency(\.uuid) var uuid

		return try! Self(
			name: .init(id: uuid(), value: .init(
				variant: .eastern,
				familyName: "Nakamoto",
				givenNames: "Satoshi",
				nickname: "Bitcoin"
			)),
			dateOfBirth: .init(id: uuid(), value: .init(year: 2009, month: 1, day: 3)),
			companyName: .init(id: uuid(), value: .init(name: "Bitcoin")),
			emailAddresses: .init(collection: [
				.init(id: uuid(), value: .init(email: "satoshi@nakamoto.bitcoin")),
				.init(id: uuid(), value: .init(email: "be.your@own.bank")),
			]),
			phoneNumbers: .init(collection: [
				.init(id: uuid(), value: .init(number: "21000000")),
				.init(id: uuid(), value: .init(number: "123456789")),
			]),
			urls: .init(collection: [
				.init(id: uuid(), value: .init(url: "bitcoin.org")),
				.init(id: uuid(), value: .init(url: "https://github.com/bitcoin-core/secp256k1")),
			]),
			postalAddresses: .init(collection: [
				.init(id: uuid(), value: .init(validating: [
					.postalCode("21 000 000"),
					.prefecture("SHA256"), .countySlashCity("Hashtown"),
					.furtherDivisionsLine0("Sound money street"),
					.furtherDivisionsLine1(""),
					.countryOrRegion(.japan),
				])),
				.init(id: uuid(), value: .init(validating: [
					.streetLine0("Copthall House"),
					.streetLine1("King street"),
					.townSlashCity("Newcastle-under-Lyme"),
					.county("Newcastle"),
					.postcode("ST5 1UE"),
					.countryOrRegion(.unitedKingdom),
				])),
			]),
			creditCards: .init(collection: [
				.init(id: uuid(), value: .init(
					expiry: .init(year: 2142, month: 12),
					holder: "Satoshi Nakamoto",
					number: "0000 0000 2100 0000",
					cvc: 512
				)),
			])
		)
	}
}
