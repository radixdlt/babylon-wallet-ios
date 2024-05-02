
// MARK: - P2P.Dapp.Response.WalletInteractionSuccessResponse.PersonaDataRequestResponseItem
extension P2P.Dapp.Response.WalletInteractionSuccessResponse {
	public struct PersonaDataRequestResponseItem: Sendable, Hashable, Encodable {
		public let name: PersonaDataEntryName?

		public let emailAddresses: OrderedSet<PersonaDataEntryEmailAddress>?
		public let phoneNumbers: OrderedSet<PersonaDataEntryPhoneNumber>?

		public init(
			name: PersonaDataEntryName? = nil,
			emailAddresses: OrderedSet<PersonaDataEntryEmailAddress>? = nil,
			phoneNumbers: OrderedSet<PersonaDataEntryPhoneNumber>? = nil
		) {
			self.name = name
			self.emailAddresses = emailAddresses
			self.phoneNumbers = phoneNumbers
		}
	}
}
