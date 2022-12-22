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
	typealias SentReceipt = P2PConnection.SentReceipt
	typealias ID = P2P.ToDapp.Response.ID
	var id: ID { responseToDapp.id }
}

#if DEBUG
public extension P2P.ToDapp.Response {
	static let placeholder: Self = .success(.init(id: .placeholder, items: []))
}

public extension ChunkingTransportOutgoingMessage {
	static let placeholder = Self(data: .deadbeef32Bytes, messageID: MessageID())
}

public extension P2PConnection.SentReceipt {
	static let placeholder = Self(messageSent: .placeholder)
}

public extension P2P.SentResponseToClient {
	static let placeholder = Self(sentReceipt: .placeholder, responseToDapp: .placeholder, client: .placeholder)
}
#endif // DEBUG
