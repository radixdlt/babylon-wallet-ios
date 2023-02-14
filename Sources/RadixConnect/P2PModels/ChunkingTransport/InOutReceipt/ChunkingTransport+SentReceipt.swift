import Foundation

// MARK: - ChunkingTransportSentReceipt
public struct ChunkingTransportSentReceipt: Sendable, Hashable, CustomStringConvertible {
	public let messageSent: ChunkingTransportOutgoingMessage
	public let confirmedReceivedAt: Date

	public init(
		messageSent: ChunkingTransportOutgoingMessage,
		confirmedReceivedAt: Date = .init()
	) {
		self.messageSent = messageSent
		self.confirmedReceivedAt = confirmedReceivedAt
	}
}

extension ChunkingTransportSentReceipt {
	public var description: String {
		"""
		confirmedReceivedAt: \(confirmedReceivedAt),
		messageSent: \(messageSent)
		"""
	}
}
