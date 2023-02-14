import Prelude

extension P2P.ToDapp {
	public struct WalletInteractionSuccessResponse: Sendable, Hashable, Encodable {
		/// *MUST* match an ID from an incoming request from Dapp.
		public let interactionId: P2P.FromDapp.WalletInteraction.ID
		public let items: Items

		public init(
			interactionId: P2P.FromDapp.WalletInteraction.ID,
			items: Items
		) {
			self.interactionId = interactionId
			self.items = items
		}
	}
}
