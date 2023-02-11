import ClientPrelude

// MARK: - P2P.SentResponseToClient
extension P2P {
	// MARK: - SentResponseToClient
	public struct SentResponseToClient: Sendable, Equatable {
		public let sentReceipt: P2PConnections.SentReceipt
		public let responseToDapp: P2P.ToDapp.WalletInteractionResponse
		public let client: P2PClient
		public init(
			sentReceipt: P2PConnections.SentReceipt,
			responseToDapp: P2P.ToDapp.WalletInteractionResponse,
			client: P2PClient
		) {
			self.sentReceipt = sentReceipt
			self.responseToDapp = responseToDapp
			self.client = client
		}
	}
}

#if DEBUG
extension P2P.ToDapp.WalletInteractionResponse {
	public static let previewValue: Self = .success(.init(
		interactionId: .previewValue,
		items: .request(.unauthorized(.init(
			oneTimeAccounts: nil
		)))
	))
}

extension ChunkingTransportOutgoingMessage {
	public static let previewValue = Self(data: .deadbeef32Bytes, messageID: MessageID())
}

extension P2PConnections.SentReceipt {
	public static let previewValue = Self(messageSent: .previewValue)
}

extension P2P.SentResponseToClient {
	public static let previewValue = Self(sentReceipt: .previewValue, responseToDapp: .previewValue, client: .previewValue)
}
#endif
