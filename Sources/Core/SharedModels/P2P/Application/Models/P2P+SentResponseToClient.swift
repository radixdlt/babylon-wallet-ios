import P2PConnection
import P2PModels
import Prelude
import ProfileModels

// MARK: - P2P.SentResponseToClient
public extension P2P {
	// MARK: - SentResponseToClient
	struct SentResponseToClient: Sendable, Equatable {
		public let sentReceipt: SentReceipt
		public let responseToDapp: P2P.ToDapp.WalletInteractionResponse
		public let client: P2PClient
		public init(
			sentReceipt: SentReceipt,
			responseToDapp: P2P.ToDapp.WalletInteractionResponse,
			client: P2PClient
		) {
			self.sentReceipt = sentReceipt
			self.responseToDapp = responseToDapp
			self.client = client
		}
	}
}

// MARK: - P2P.SentResponseToClient.SentReceipt
public extension P2P.SentResponseToClient {
	typealias SentReceipt = P2PConnections.SentReceipt
//	typealias ID = P2P.ToDapp.Response.ID
//	var id: ID { responseToDapp.id }
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
#endif // DEBUG
