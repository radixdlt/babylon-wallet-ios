import Prelude

public extension P2P.ToDapp {
	struct WalletInteractionSuccessResponse: Sendable, Hashable, Encodable {
		/// *MUST* match an ID from an incoming request from Dapp.
		public let interactionId: P2P.FromDapp.WalletInteraction.ID
//		public let items: [P2P.ToDapp.WalletResponseItem]

		public init(
			interactionId: P2P.FromDapp.WalletInteraction.ID
//			items: [P2P.ToDapp.WalletResponseItem]
		) {
			self.interactionId = interactionId
//			self.items = items
		}
	}
}
