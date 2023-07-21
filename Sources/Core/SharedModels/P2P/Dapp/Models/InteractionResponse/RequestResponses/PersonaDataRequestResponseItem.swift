import Prelude
import Profile

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
			switch PersonaData.Entry.Kind.fullName {
			case .fullName, .dateOfBirth, .companyName, .emailAddress, .phoneNumber, .url, .postalAddress, .creditCard: break
			}
		}
	}
}
