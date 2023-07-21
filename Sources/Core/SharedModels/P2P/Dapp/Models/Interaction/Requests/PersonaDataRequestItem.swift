import Prelude
import Profile

extension P2P.Dapp.Request {
	public struct PersonaDataRequestItem: Sendable, Hashable, Decodable {
		public let isRequestingName: Bool?
		public let isRequestingDateOfBirth: Bool?
		public let isRequestingCompanyName: Bool?
		public let emailAddressesRequested: RequestedNumber?
		public let phoneNumbersAddressesRequested: RequestedNumber?
		public let urlsRequested: RequestedNumber?
		public let postalAddressesRequested: RequestedNumber?
		public let creditCardsRequested: RequestedNumber?

		public init(
			isRequestingName: Bool? = nil,
			isRequestingDateOfBirth: Bool? = nil,
			isRequestingCompanyName: Bool? = nil,
			emailAddressesRequested: RequestedNumber? = nil,
			phoneNumbersAddressesRequested: RequestedNumber? = nil,
			urlsRequested: RequestedNumber? = nil,
			postalAddressesRequested: RequestedNumber? = nil,
			creditCardsRequested: RequestedNumber? = nil
		) {
			// The only purpose of this switch is to make sure we get a compilation error when we add a new PersonaData.Entry kind, so
			// we do not forget to handle it here.
			switch PersonaData.Entry.Kind.fullName {
			case .fullName, .dateOfBirth, .companyName, .emailAddress, .phoneNumber, .url, .postalAddress, .creditCard: break
			}

			self.isRequestingName = isRequestingName
			self.isRequestingDateOfBirth = isRequestingDateOfBirth
			self.isRequestingCompanyName = isRequestingCompanyName
			self.emailAddressesRequested = emailAddressesRequested
			self.phoneNumbersAddressesRequested = phoneNumbersAddressesRequested
			self.urlsRequested = urlsRequested
			self.postalAddressesRequested = postalAddressesRequested
			self.creditCardsRequested = creditCardsRequested
		}
	}
}
