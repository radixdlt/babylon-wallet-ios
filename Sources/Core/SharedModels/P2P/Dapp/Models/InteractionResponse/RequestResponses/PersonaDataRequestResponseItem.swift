import Prelude

extension P2P.Dapp.Response.WalletInteractionSuccessResponse {
	public struct PersonaDataRequestResponseItem: Sendable, Hashable, Encodable {
		public let fields: [P2P.Dapp.Response.PersonaData]

		public init(
			fields: [P2P.Dapp.Response.PersonaData]
		) {
			self.fields = fields
		}
	}
}
