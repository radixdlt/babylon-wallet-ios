import Prelude
import Profile

extension P2P.Dapp.Response.WalletInteractionSuccessResponse {
	public struct PersonaDataRequestResponseItem: Sendable, Hashable, Encodable {
		public let name: PersonaData.Name?
		public let dateOfBirth: PersonaData.DateOfBirth?
		public let emailAddresses: OrderedSet<PersonaData.EmailAddress>?
		public let postalAddresses: OrderedSet<PersonaData.PostalAddress>?
		public let phoneNumbers: OrderedSet<PersonaData.PhoneNumber>?
		public let creditCards: OrderedSet<PersonaData.CreditCard>?

		public init(
			name: PersonaData.Name? = nil,
			dateOfBirth: PersonaData.DateOfBirth? = nil,
			emailAddresses: OrderedSet<PersonaData.EmailAddress>? = nil,
			postalAddresses: OrderedSet<PersonaData.PostalAddress>? = nil,
			phoneNumbers: OrderedSet<PersonaData.PhoneNumber>? = nil,
			creditCards: OrderedSet<PersonaData.CreditCard>? = nil
		) {
			self.name = name
			self.dateOfBirth = dateOfBirth
			self.emailAddresses = emailAddresses
			self.postalAddresses = postalAddresses
			self.phoneNumbers = phoneNumbers
			self.creditCards = creditCards
		}
	}
}
