import Prelude

// MARK: - ChunkingTransportIncomingMessage
public struct ChunkingTransportIncomingMessage: Sendable, Hashable, CustomStringConvertible {
	public let messagePayload: Data
	public let messageID: MessageID

	/// Used to guarantee filter messages by their content based uniqueID used ti ensure we never in
	/// the application display the same Dapp Request twice. This is a lowerlevel identifier than `messageID`,
	/// two Dapp Requests might have two different `messageID`, but the same `messageHash`, and messageHash itself
	/// is the hash of a CAP21 WalletRequest which itself contains a Dapp Request ID, which is different between
	/// different Dapp Requests. The Wallet JS SDK will re-send a WalletRequest if the iOS client does not
	/// send a Msg Read Confirmation response back within a short period of time (typically 1 second) and we
	/// can use this `messageHash` to identify that it is the same message but resent. It will then have the same
	/// Dapp Request ID and thus the same `messageHash`, but different `messageID`s.
	public let messageHash: Data

	public init(messagePayload: Data, messageID: MessageID, messageHash: Data) {
		self.messagePayload = messagePayload
		self.messageID = messageID
		self.messageHash = messageHash
	}
}

extension ChunkingTransportIncomingMessage {
	public typealias MessageID = ChunkedMessagePackage.MessageID

	public var description: String {
		"""
		messageID: \(messageID),
		messageHash: #\(messageHash.hex()),
		messagePayload: #\(messagePayload.count) bytes
		"""
	}
}
