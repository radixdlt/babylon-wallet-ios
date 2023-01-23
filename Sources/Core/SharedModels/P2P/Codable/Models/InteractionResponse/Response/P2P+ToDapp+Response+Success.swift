
public extension P2P.ToDapp.Response {
	/// Called `WalletResponse` in [CAP21][cap]
	///
	/// [cap]: https://radixdlt.atlassian.net/wiki/spaces/AT/pages/2712895489/CAP-21+Message+format+between+dApp+and+wallet#Wallet-SDK-%E2%86%94%EF%B8%8F-Wallet-messages
	///
	struct Success: Sendable, Hashable, Encodable, Identifiable {
		/// *MUST* match an ID from an incoming request from Dapp.
		public let id: P2P.FromDapp.WalletInteraction.ID

		public let items: [P2P.ToDapp.WalletResponseItem]

		public init(
			id: P2P.FromDapp.WalletInteraction.ID,
			items: [P2P.ToDapp.WalletResponseItem]
		) {
			self.id = id
			self.items = items
		}
	}
}
