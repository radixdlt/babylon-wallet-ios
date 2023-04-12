import Prelude

// MARK: - P2P.ToDapp.WalletInteractionSuccessResponse.OngoingPersonaDataRequestResponseItem
extension P2P.ToDapp.WalletInteractionSuccessResponse {
	public struct OneTimePersonaDataRequestResponseItem: Sendable, Hashable, Encodable {
		public let fields: [P2P.ToDapp.PersonaData]

		public init(fields: [P2P.ToDapp.PersonaData]) {
			self.fields = fields
		}
	}
}
