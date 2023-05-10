import Prelude

extension P2P.Dapp.Response.WalletInteractionSuccessResponse {
	public struct PersonaDataRequestResponseItem: Sendable, Hashable, Encodable {
		public let isOneTime: Bool
		public let fields: [P2P.Dapp.Response.PersonaData]

		public init(
			isOneTime: Bool,
			fields: [P2P.Dapp.Response.PersonaData]
		) {
			self.isOneTime = isOneTime
			self.fields = fields
		}
	}
}
