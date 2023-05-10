import Prelude

extension P2P.Dapp.Request {
	public struct PersonaDataRequestItem: Sendable, Hashable, Decodable {
		public let isOneTime: Bool
		public let fields: Set<P2P.Dapp.Request.PersonaDataField>

		public init(
			isOneTime: Bool,
			fields: Set<P2P.Dapp.Request.PersonaDataField>
		) {
			self.isOneTime = isOneTime
			self.fields = fields
		}
	}
}
