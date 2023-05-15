import Prelude

extension P2P.Dapp.Request {
	public struct PersonaDataRequestItem: Sendable, Hashable, Decodable {
		public let fields: Set<P2P.Dapp.Request.PersonaDataField>

		public init(
			fields: Set<P2P.Dapp.Request.PersonaDataField>
		) {
			self.fields = fields
		}
	}
}
