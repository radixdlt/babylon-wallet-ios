import Algorithms
import CryptoKit
import Foundation

// MARK: - MessageSplitter
struct MessageSplitter: Sendable {
	// According to CAP19
	static let messageSizeChunkLimitDefault = 15441
	private let messageSizeChunkLimit: Int

	init(messageSizeChunkLimit: Int = MessageSplitter.messageSizeChunkLimitDefault) {
		self.messageSizeChunkLimit = messageSizeChunkLimit
	}

	func split(message: Data, messageID: ChunkedMessagePackage.MessageID) -> [ChunkedMessagePackage] {
		let chunks = message.chunks(ofCount: messageSizeChunkLimit)
		let hashOfMessage = Data(SHA256.hash(data: message))

		let metaDataPackage = ChunkedMessagePackage.metaData(
			.init(
				messageId: messageID,
				chunkCount: chunks.count,
				messageByteCount: message.count,
				hashOfMessage: .init(data: hashOfMessage)
			)
		)

		let chunkPackages: [ChunkedMessagePackage] = chunks.enumerated().map { chunkIndex, chunkData in
			ChunkedMessagePackage.chunk(
				.init(
					messageId: messageID,
					chunkIndex: chunkIndex,
					chunkData: chunkData
				)
			)
		}

		return [metaDataPackage] + chunkPackages
	}
}
