import Prelude
import Profile

extension P2P.Dapp.Request {
	public struct PersonaDataRequestItem: Sendable, Hashable, Decodable {
		public let isRequestingName: Bool
		public let isRequestingDateOfBirth: Bool
		public let postalAddressesRequested: RequestedNumber?
		public let emailAddressesRequested: RequestedNumber?
		public let phoneNumbersAddressesRequested: RequestedNumber?

		public init(
			isRequestingName: Bool = false,
			isRequestingDateOfBirth: Bool = false,
			postalAddressesRequested: RequestedNumber? = nil,
			emailAddressesRequested: RequestedNumber? = nil,
			phoneNumbersAddressesRequested: RequestedNumber? = nil
		) {
			self.isRequestingName = isRequestingName
			self.isRequestingDateOfBirth = isRequestingDateOfBirth
			self.postalAddressesRequested = postalAddressesRequested
			self.emailAddressesRequested = emailAddressesRequested
			self.phoneNumbersAddressesRequested = phoneNumbersAddressesRequested
		}
	}
}
