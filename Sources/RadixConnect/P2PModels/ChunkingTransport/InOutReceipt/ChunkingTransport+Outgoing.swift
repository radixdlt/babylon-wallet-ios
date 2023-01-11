import Foundation

// MARK: - ChunkingTransportOutgoingMessage
public struct ChunkingTransportOutgoingMessage: Sendable, Hashable, CustomStringConvertible {
	public let messageID: MessageID
	public let data: Data

	public init(data: Data, messageID: MessageID) {
		self.data = data
		self.messageID = messageID
	}
}

public extension ChunkingTransportOutgoingMessage {
	typealias MessageID = ChunkedMessagePackage.MessageID
	var description: String {
		"""
		messageID: \(messageID),
		data: #\(data.count) bytes
		"""
	}
}
