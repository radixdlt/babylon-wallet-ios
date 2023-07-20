import Prelude
import Profile

// MARK: - P2P.Dapp.Response.WalletInteractionSuccessResponse.PersonaDataRequestResponseItem
extension P2P.Dapp.Response.WalletInteractionSuccessResponse {
	public struct PersonaDataRequestResponseItem: Sendable, Hashable, Encodable {
		public let name: PersonaData.Name?
		public let dateOfBirth: PersonaData.DateOfBirth?
		public let companyName: PersonaData.CompanyName?

		public let emailAddresses: OrderedSet<PersonaData.EmailAddress>?
		public let phoneNumbers: OrderedSet<PersonaData.PhoneNumber>?
		public let urls: OrderedSet<PersonaData.AssociatedURL>?
		public let postalAddresses: OrderedSet<PersonaData.PostalAddress>?
		public let creditCards: OrderedSet<PersonaData.CreditCard>?

		public init(
			name: PersonaData.Name? = nil,
			dateOfBirth: PersonaData.DateOfBirth? = nil,
			companyName: PersonaData.CompanyName? = nil,
			emailAddresses: OrderedSet<PersonaData.EmailAddress>? = nil,
			phoneNumbers: OrderedSet<PersonaData.PhoneNumber>? = nil,
			urls: OrderedSet<PersonaData.AssociatedURL>? = nil,
			postalAddresses: OrderedSet<PersonaData.PostalAddress>? = nil,
			creditCards: OrderedSet<PersonaData.CreditCard>? = nil
		) {
			self.name = name
			self.dateOfBirth = dateOfBirth
			self.companyName = companyName
			self.emailAddresses = emailAddresses
			self.phoneNumbers = phoneNumbers
			self.urls = urls
			self.postalAddresses = postalAddresses
			self.creditCards = creditCards

			// The only purpose of this switch is to make sure we get a compilation error when we add a new PersonaData.Entry kind, so
			// we do not forget to handle it here.
			switch PersonaData.Entry.Kind.name {
			case .name, .dateOfBirth, .companyName, .emailAddress, .phoneNumber, .url, .postalAddress, .creditCard: break
			}
		}
	}
}

extension P2P.Dapp.Response.WalletInteractionSuccessResponse.PersonaDataRequestResponseItem {
	public init(_ personaData: PersonaData, request: P2P.Dapp.Request.PersonaDataRequestItem) throws {
		let issues = personaData.requestIssues(request)
		guard issues.isEmpty else {
			throw PersonaDataRequestError(issues: issues)
		}
		self.init(personaData)
	}

	public init(_ personaData: PersonaData) {
		self.init(
			name: personaData.name?.value,
			dateOfBirth: personaData.dateOfBirth?.value,
			companyName: personaData.companyName?.value,
			emailAddresses: personaData.emailAddresses.values,
			phoneNumbers: personaData.phoneNumbers.values,
			urls: personaData.urls.values,
			postalAddresses: personaData.postalAddresses.values,
			creditCards: personaData.creditCards.values
		)
	}

	public struct PersonaDataRequestError: Error {
		let issues: [PersonaData.Entry.Kind: P2P.Dapp.Request.Issue]
	}
}

extension PersonaData.CollectionOfIdentifiedEntries {
	public var values: OrderedSet<Value>? {
		try? .init(validating: collection.elements.map(\.value))
	}
}
