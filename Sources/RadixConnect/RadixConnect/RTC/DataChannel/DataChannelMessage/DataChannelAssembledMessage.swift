import CryptoKit
import Foundation
import Prelude

// MARK: - DataChannelClient.AssembledMessage
extension DataChannelClient {
	public struct AssembledMessage: Equatable, Sendable {
		// According to CAP19
		static let chunkSize = 15441

		public let idOfChunks: Message.ID
		public let messageContent: Data
		public let messageHash: Data

		public init(message: Data, id: Message.ID, messageHash: Data) {
			self.idOfChunks = id
			self.messageContent = message
			self.messageHash = messageHash
		}

		public init(message: Data, id: Message.ID) throws {
			try self.init(message: message, id: id, messageHash: message.hash())
		}
	}
}

extension DataChannelClient.AssembledMessage {
	static func assembleFrom(
		chunks: [DataChannelClient.Message.ChunkedMessage.ChunkPackage],
		metaData: DataChannelClient.Message.ChunkedMessage.MetaDataPackage
	) throws -> Self {
		// For now there is only one error type that can be handled in any manner - `messageHashesMismatch`
		// thus, collapse all possible errors in this one.
		func error() -> DataChannelClient.Message.Receipt.ReceiveError {
			.init(messageId: metaData.messageId, error: .messageHashesMismatch)
		}

		guard !chunks.isEmpty else {
			loggerGlobal.error("'packages' array is empty, not allowed.")
			throw error()
		}

		let expectedHash = metaData.hashOfMessage.data
		let chunkCount = metaData.chunkCount

		// Mutable since we allow incorrect ordering of chunked packages, and sort on index.
		var chunks = chunks

		let indices = chunks.map(\.chunkIndex)
		let expectedOrderOfIndices = [Int](0 ..< chunkCount)

		if indices != expectedOrderOfIndices {
			let indicesDifference = Set(indices).symmetricDifference(Set(expectedOrderOfIndices))
			guard indicesDifference.isEmpty else {
				loggerGlobal.error("Incorrect indices of chunked packages, got difference: \(indicesDifference)")
				throw error()
			}

			// Chunked packages are not ordered properly
			loggerGlobal.warning("Chunked packages are not ordered, either other client are sending packages in incorrect order, or we have received them over the communication channel in the wrong order. We will reorder them.")
			chunks.sort(by: <)
		}

		let message = chunks.map(\.chunkData).reduce(Data(), +)

		guard message.count == metaData.messageByteCount else {
			loggerGlobal.error("Re-assembled message has #\(message.count) bytes, but MetaData package stated a message byte count of: #\(metaData.messageByteCount) bytes.")
			throw error()
		}

		let hash = try message.hash()
		guard hash == expectedHash else {
			let hashHex = hash.hex()
			let expectedHashHex = expectedHash.hex()
			loggerGlobal.critical("Hash of re-assembled message differs from expected one. Calculated hash: '\(hashHex)', but MetaData package stated: '\(expectedHashHex)'.")
			throw error()
		}

		return .init(message: message, id: metaData.messageId, messageHash: hash)
	}
}

extension DataChannelClient.AssembledMessage {
	func split() -> [DataChannelClient.Message.ChunkedMessage] {
		let chunks = messageContent.chunks(ofCount: Self.chunkSize)

		let metaDataPackage = DataChannelClient.Message.ChunkedMessage.metaData(
			.init(
				messageId: idOfChunks,
				chunkCount: chunks.count,
				messageByteCount: messageContent.count,
				hashOfMessage: .init(data: messageHash)
			)
		)

		let chunkPackages: [DataChannelClient.Message.ChunkedMessage] = chunks.enumerated().map { chunkIndex, chunkData in
			DataChannelClient.Message.ChunkedMessage.chunk(
				.init(
					messageId: idOfChunks,
					chunkIndex: chunkIndex,
					chunkData: chunkData
				)
			)
		}

		return [metaDataPackage] + chunkPackages
	}
}
