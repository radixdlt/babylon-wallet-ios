import Prelude
import Profile

extension P2P.Dapp.Request {
	public struct PersonaDataRequestItem: Sendable, Hashable, Decodable {
		public let isRequestingName: Bool?
		public let numberOfRequestedEmailAddresses: RequestedNumber?
		public let numberOfRequestedPhoneNumbers: RequestedNumber?

		public init(
			isRequestingName: Bool?,
			numberOfRequestedEmailAddresses: RequestedNumber? = nil,
			numberOfRequestedPhoneNumbers: RequestedNumber? = nil
		) {
			// The only purpose of this switch is to make sure we get a compilation error when we add a new PersonaData.Entry kind, so
			// we do not forget to handle it here.
			switch PersonaData.Entry.Kind.name {
			case .name, .dateOfBirth, .companyName, .emailAddress, .phoneNumber, .url, .postalAddress, .creditCard: break
			}

			self.isRequestingName = isRequestingName
			self.numberOfRequestedEmailAddresses = numberOfRequestedEmailAddresses
			self.numberOfRequestedPhoneNumbers = numberOfRequestedPhoneNumbers
		}
	}
}
