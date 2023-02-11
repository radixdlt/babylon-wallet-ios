import Prelude

// MARK: - ChunkedMessageChunkPackage
public struct ChunkedMessageChunkPackage: Sendable, Codable, Comparable {
	public let messageId: ChunkedMessagePackage.MessageID
	public let chunkIndex: Int
	public let chunkData: Data

	public init(
		messageID messageId: ChunkedMessagePackage.MessageID,
		chunkIndex: Int,
		chunkData: Data
	) {
		self.messageId = messageId
		self.chunkIndex = chunkIndex
		self.chunkData = chunkData
	}
}

// MARK: Decodable
extension ChunkedMessageChunkPackage {
	public enum CodingKeys: String, CodingKey {
		case messageId, chunkIndex, chunkData
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.messageId = try container.decode(ChunkedMessagePackage.MessageID.self, forKey: .messageId)
		self.chunkIndex = try container.decode(Int.self, forKey: .chunkIndex)
		let chunkDataAsString = try container.decode(String.self, forKey: .chunkData)

		if let chunkData = Data(base64Encoded: chunkDataAsString) {
			self.chunkData = chunkData
		} else {
			loggerGlobal.warning("Received chunkData as HEX, should have been Base64. Please ask Browser Extension client devs to fix this :).")
			self.chunkData = try Data(hex: chunkDataAsString)
		}
	}
}

// MARK: Comparable
extension ChunkedMessageChunkPackage {
	// Comparable so we can sort them conveniently if received unsorted.
	public static func < (lhs: ChunkedMessageChunkPackage, rhs: ChunkedMessageChunkPackage) -> Bool {
		lhs.chunkIndex < rhs.chunkIndex
	}
}

#if DEBUG
extension ChunkedMessageChunkPackage {
	public static func placeholder(index: Int) -> Self {
		.init(
			messageID: .deadbeef32Bytes,
			chunkIndex: index,
			chunkData: .deadbeef32Bytes
		)
	}
}
#endif // DEBUG
