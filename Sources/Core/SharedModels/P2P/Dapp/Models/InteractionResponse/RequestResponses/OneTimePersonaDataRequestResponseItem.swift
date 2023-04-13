import Prelude

// MARK: - P2P.Dapp.Response.WalletInteractionSuccessResponse.OngoingPersonaDataRequestResponseItem
extension P2P.Dapp.Response.WalletInteractionSuccessResponse {
	public struct OneTimePersonaDataRequestResponseItem: Sendable, Hashable, Encodable {
		public let fields: [P2P.Dapp.Response.PersonaData]

		public init(fields: [P2P.Dapp.Response.PersonaData]) {
			self.fields = fields
		}
	}
}
