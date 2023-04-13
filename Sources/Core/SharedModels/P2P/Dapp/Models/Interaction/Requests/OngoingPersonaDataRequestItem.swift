import Prelude

// MARK: - P2P.Dapp.Request.OngoingPersonaDataRequestItem
extension P2P.Dapp.Request {
	public struct OngoingPersonaDataRequestItem: Sendable, Hashable, Decodable {
		public let fields: Set<P2P.Dapp.Request.PersonaDataField>

		public init(fields: Set<P2P.Dapp.Request.PersonaDataField>) {
			self.fields = fields
		}
	}
}
