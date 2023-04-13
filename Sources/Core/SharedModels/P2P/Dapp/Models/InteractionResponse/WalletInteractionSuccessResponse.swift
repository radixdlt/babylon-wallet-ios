import Prelude

extension P2P.Dapp.Response {
	public struct WalletInteractionSuccessResponse: Sendable, Hashable, Encodable {
		/// *MUST* match an ID from an incoming request from Dapp.
		public let interactionId: P2P.Dapp.Request.ID
		public let items: Items

		public init(
			interactionId: P2P.Dapp.Request.ID,
			items: Items
		) {
			self.interactionId = interactionId
			self.items = items
		}
	}
}
