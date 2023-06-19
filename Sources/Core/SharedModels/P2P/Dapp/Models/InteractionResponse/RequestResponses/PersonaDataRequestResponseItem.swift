import Prelude
import Profile

extension P2P.Dapp.Response.WalletInteractionSuccessResponse {
	public struct PersonaDataRequestResponseItem: Sendable, Hashable, Encodable {
		public let name: PersonaDataEntry.Name?
		public let dateOfBirth: PersonaDataEntry.DateOfBirth?
		public let emailAddresses: OrderedSet<PersonaDataEntry.EmailAddress>?
		public let postalAddresses: OrderedSet<PersonaDataEntry.PostalAddress>?
		public let phoneNumbers: OrderedSet<PersonaDataEntry.PhoneNumber>?

		public init(
			name: PersonaDataEntry.Name? = nil,
			dateOfBirth: PersonaDataEntry.DateOfBirth? = nil,
			emailAddresses: OrderedSet<PersonaDataEntry.EmailAddress>? = nil,
			postalAddresses: OrderedSet<PersonaDataEntry.PostalAddress>? = nil,
			phoneNumbers: OrderedSet<PersonaDataEntry.PhoneNumber>? = nil
		) {
			self.name = name
			self.dateOfBirth = dateOfBirth
			self.emailAddresses = emailAddresses
			self.postalAddresses = postalAddresses
			self.phoneNumbers = phoneNumbers
		}
	}
}
