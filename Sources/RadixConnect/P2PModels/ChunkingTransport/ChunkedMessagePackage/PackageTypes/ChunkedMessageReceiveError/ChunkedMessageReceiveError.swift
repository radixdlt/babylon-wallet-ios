import Foundation

// MARK: - ChunkedMessageReceiveError
public struct ChunkedMessageReceiveError: LocalizedError, Codable, Sendable, Hashable {
	public let messageId: ChunkedMessagePackage.MessageID
	public let error: Reason
	public init(messageId: ChunkedMessagePackage.MessageID, error: Reason) {
		self.messageId = messageId
		self.error = error
	}
}

// MARK: ChunkedMessageReceiveError.Reason
public extension ChunkedMessageReceiveError {
	enum Reason: String, Sendable, Hashable, Codable {
		case messageHashesMismatch
	}
}
