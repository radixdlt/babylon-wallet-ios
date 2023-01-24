import P2PConnection
import P2PModels
import Prelude
import ProfileModels

// MARK: - P2P.SentResponseToClient
public extension P2P {
	// MARK: - SentResponseToClient
	struct SentResponseToClient: Sendable, Equatable {
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
public extension P2P.ToDapp.WalletInteractionResponse {
	static let previewValue: Self = .success(.init(
		interactionId: .previewValue,
		items: .request(.unauthorized(.init(
			oneTimeAccounts: nil
		)))
	))
}

public extension ChunkingTransportOutgoingMessage {
	static let previewValue = Self(data: .deadbeef32Bytes, messageID: MessageID())
}

public extension P2PConnections.SentReceipt {
	static let previewValue = Self(messageSent: .previewValue)
}

public extension P2P.SentResponseToClient {
	static let previewValue = Self(sentReceipt: .previewValue, responseToDapp: .previewValue, client: .previewValue)
}
#endif
