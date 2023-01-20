import Algorithms
import Cryptography
import P2PModels
import Prelude

// MARK: - RadixHasher
public enum RadixHasher {
	static func hash(data: Data) throws -> Data {
		Data(SHA256.hash(data: data))
	}
}

// MARK: - MessageSplitter
public final class MessageSplitter: Sendable {
	private let messageSizeChunkLimit: Int

	public init(
		messageSizeChunkLimit: Int = MessageSplitter.messageSizeChunkLimitDefault
	) {
		self.messageSizeChunkLimit = messageSizeChunkLimit
	}
}

public extension MessageSplitter {
	typealias ID = ChunkedMessagePackage.MessageID
	typealias Split = @Sendable (Data, ID) throws -> [ChunkedMessagePackage]

	// According to CAP19
	static let messageSizeChunkLimitDefault = 15441
}

public extension MessageSplitter {
	func split(message: Data, messageID: ID) throws -> [ChunkedMessagePackage] {
		let chunks = message.chunks(ofCount: messageSizeChunkLimit)
		let hashOfMessage = try RadixHasher.hash(data: message)

		let metaDataPackage = ChunkedMessagePackage.metaData(
			.init(
				messageID: messageID,
				chunkCount: chunks.count,
				messageByteCount: message.count,
				hashOfMessage: .init(data: hashOfMessage)
			)
		)

		let chunkPackages: [ChunkedMessagePackage] = chunks.enumerated().map { chunkIndex, chunkData in
			ChunkedMessagePackage.chunk(
				.init(
					messageID: messageID,
					chunkIndex: chunkIndex,
					chunkData: chunkData
				)
			)
		}

		return [metaDataPackage] + chunkPackages
	}
}
