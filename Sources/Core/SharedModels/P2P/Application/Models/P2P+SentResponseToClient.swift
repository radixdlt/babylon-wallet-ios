import Foundation
import P2PConnection
import P2PModels
import Profile

// MARK: - P2P.SentResponseToClient
public extension P2P {
	// MARK: - SentResponseToClient
	struct SentResponseToClient: Sendable, Equatable, Identifiable {
		public let sentReceipt: SentReceipt
		public let responseToDapp: P2P.ToDapp.Response
		public let client: P2PClient
		public init(
			sentReceipt: SentReceipt,
			responseToDapp: P2P.ToDapp.Response,
			client: P2PClient
		) {
			self.sentReceipt = sentReceipt
			self.responseToDapp = responseToDapp
			self.client = client
		}
	}
}

public extension P2P.SentResponseToClient {
	typealias SentReceipt = P2PConnections.SentReceipt
	typealias ID = P2P.ToDapp.Response.ID
	var id: ID { responseToDapp.id }
}

#if DEBUG
public extension P2P.ToDapp.Response {
	static let previewValue: Self = .success(.init(id: .previewValue, items: []))
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
