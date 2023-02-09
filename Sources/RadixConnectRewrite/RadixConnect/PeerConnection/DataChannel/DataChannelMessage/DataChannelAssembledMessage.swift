import CryptoKit
import Foundation
import Prelude

struct DataChannelAssembledMessage: Equatable {
        // According to CAP19
        static let chunkSize = 15441

        let idOfChunks: DataChannelMessage.ID
        let messageContent: Data
        let messageHash: Data

        init(message: Data, id: DataChannelMessage.ID, messageHash: Data) {
                self.idOfChunks = id
                self.messageContent = message
                self.messageHash = messageHash
        }

        init(message: Data, id: DataChannelMessage.ID) {
                self.init(message: message, id: id, messageHash: message.hash)
        }
}

extension Data {
        var hash: Data {
                Data(SHA256.hash(data: self))
        }
}

extension DataChannelAssembledMessage {
        static func assembleFrom(
                chunks: [DataChannelMessage.ChunkedMessage.ChunkPackage],
                metaData: DataChannelMessage.ChunkedMessage.MetaDataPackage
        ) throws -> Self {
                // For now ther is only one error type that can be handled in any manner - `messageHashesMismatch`
                // thus, collapse all possible errors in this one.
                func error() -> DataChannelMessage.Receipt.ReceiveError {
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

                let hash = message.hash
                guard hash == expectedHash else {
                        let hashHex = hash.hex()
                        let expectedHashHex = expectedHash.hex()
                        loggerGlobal.critical("Hash of re-assembled message differs from expected one. Calculated hash: '\(hashHex)', but MetaData package stated: '\(expectedHashHex)'.")
                        throw error()
                }

                return DataChannelAssembledMessage(message: message, id: metaData.messageId, messageHash: hash)
        }
}

extension DataChannelAssembledMessage {
        func split() -> [DataChannelMessage.ChunkedMessage] {
                let chunks = messageContent.chunks(ofCount: Self.chunkSize)

                let metaDataPackage = DataChannelMessage.ChunkedMessage.metaData(
                        .init(
                                messageId: idOfChunks,
                                chunkCount: chunks.count,
                                messageByteCount: messageContent.count,
                                hashOfMessage: .init(data: messageHash)
                        )
                )

                let chunkPackages: [DataChannelMessage.ChunkedMessage] = chunks.enumerated().map { chunkIndex, chunkData in
                        DataChannelMessage.ChunkedMessage.chunk(
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
