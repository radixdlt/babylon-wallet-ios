import Foundation

public struct ChunkedMessageReceiveConfirmation: Codable, Sendable & Equatable, Error {
	public let messageId: ChunkedMessagePackage.MessageID
	public init(messageID messageId: ChunkedMessagePackage.MessageID) {
		self.messageId = messageId
	}
}
