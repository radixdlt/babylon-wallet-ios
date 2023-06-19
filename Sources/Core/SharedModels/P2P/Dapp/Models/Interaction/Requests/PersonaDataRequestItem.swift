import Prelude
import Profile

extension P2P.Dapp.Request {
	public struct PersonaDataRequestItem: Sendable, Hashable, Decodable {
		public let requestsName: Bool
		public let requestDateOfBirth: Bool
		public let postalAddressesRequested: RequestedNumber?
		public let emailAddressesRequested: RequestedNumber?
		public let phoneNumbersAddressesRequested: RequestedNumber?
	}
}
