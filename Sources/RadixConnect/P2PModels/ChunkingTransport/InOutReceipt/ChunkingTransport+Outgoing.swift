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

extension ChunkingTransportOutgoingMessage {
	public typealias MessageID = ChunkedMessagePackage.MessageID
	public var description: String {
		"""
		messageID: \(messageID),
		data: #\(data.count) bytes
		"""
	}
}
