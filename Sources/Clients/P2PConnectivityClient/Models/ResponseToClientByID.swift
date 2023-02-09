import ClientPrelude

// MARK: - P2P.ResponseToClientByID
public extension P2P {
	// MARK: - ResponseToClientByID
	struct ResponseToClientByID: Sendable, Hashable {
		public let connectionID: P2PConnectionID
		public let responseToDapp: ToDapp.WalletInteractionResponse
		public init(
			connectionID: P2PConnectionID,
			responseToDapp: ToDapp.WalletInteractionResponse
		) {
			self.connectionID = connectionID
			self.responseToDapp = responseToDapp
		}
	}
}
