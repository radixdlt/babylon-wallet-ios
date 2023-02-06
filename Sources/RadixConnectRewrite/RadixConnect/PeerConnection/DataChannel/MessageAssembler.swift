import Foundation
import Prelude

// MARK: - MessageAssembler
struct MessageAssembler: Sendable {
        enum IncommingMessage: Sendable {
                case message(AssembledMessage)
                case receiveConfirmation(ChunkedMessagePackage.ReceiveConfirmation)
        }
}

// MARK: - AssembledMessage
struct AssembledMessage: Sendable, Hashable {
        let idOfChunks: ChunkedMessagePackage.MessageID
        let messageContent: Data
        let messageHash: Data
}

extension MessageAssembler {
        enum Error: LocalizedError, Sendable {
                case foundReceiveMessageError(ChunkedMessagePackage.ReceiveError)
                case parseError(ParseError)
                case messageByteCountMismatch(got: Int, butMetaDataPackageStated: Int)
                case hashMismatch(calculated: String, butExpected: String)

                public enum ParseError: LocalizedError, Sendable, Hashable {
                        case noPackages
                        case noMetaDataPackage
                        case foundMultipleMetaDataPackages
                        case metaDataPackageStatesZeroChunkPackages
                        case invalidNumberOfChunkedPackages(got: Int, butMetaDataPackageStated: Int)

                        /// E.g. if we only received chunked packages with indices of: `[1, 2, 3]` (instead of `[0, 1, 2]`).
                        /// We do not throw this error if we receive chunked packages unordered, i.e. indices of `[1, 0, 2]` is
                        /// allowed (however, inaccurate) because we can simple correct the order.
                        case incorrectIndicesOfChunkedPackages
                }
        }

        func assemble(chunks: [ChunkedMessagePackage.ChunkPackage], metaData: ChunkedMessagePackage.MetaDataPackage) throws -> AssembledMessage {
                guard !chunks.isEmpty else {
                        loggerGlobal.error("'packages' array is empty, not allowed.")
                        throw Error.parseError(.noPackages)
                }

                let expectedHash = metaData.hashOfMessage.data
                let chunkCount = metaData.chunkCount

                // Mutable since we allow incorrect ordering of chunked packages, and sort on index.
                var chunks = chunks

                guard chunks.count > 0 else {
                        loggerGlobal.error("Invalid number of chunked packages, metadata package states: #\(chunkCount) but got: #\(chunks.count).")
                        throw Error.parseError(.invalidNumberOfChunkedPackages(
                                got: chunks.count,
                                butMetaDataPackageStated: chunkCount
                        ))
                }

                let indices = chunks.map(\.chunkIndex)
                let expectedOrderOfIndices = [Int](0..<chunkCount)

                if indices != expectedOrderOfIndices {
                        let indicesDifference = Set(indices).symmetricDifference(Set(expectedOrderOfIndices))
                        guard indicesDifference.isEmpty else {
                                loggerGlobal.error("Incorrect indices of chunked packages, got difference: \(indicesDifference)")
                                throw Error.parseError(.incorrectIndicesOfChunkedPackages)
                        }

                        // Chunked packages are not ordered properly
                        loggerGlobal.warning("Chunked packages are not ordered, either other client are sending packages in incorrect order, or we have received them over the communication channel in the wrong order. We will reorder them.")
                        chunks.sort(by: <)
                }

                let message = chunks.map(\.chunkData).reduce(Data(), +)

                guard message.count == metaData.messageByteCount else {
                        loggerGlobal.error("Re-assembled message has #\(message.count) bytes, but MetaData package stated a message byte count of: #\(metaData.messageByteCount) bytes.")
                        throw Error.messageByteCountMismatch(
                                got: message.count,
                                butMetaDataPackageStated: metaData.messageByteCount
                        )
                }

                let hash = try RadixHasher.hash(data: message)
                guard hash == expectedHash else {
                        let hashHex = hash.hex()
                        let expectedHashHex = expectedHash.hex()
                        loggerGlobal.critical("Hash of re-assembled message differs from expected one. Calculated hash: '\(hashHex)', but MetaData package stated: '\(expectedHashHex)'.")
                        throw Error.hashMismatch(
                                calculated: hashHex,
                                butExpected: expectedHashHex
                        )
                }

                return AssembledMessage(idOfChunks: metaData.messageId, messageContent: message, messageHash: hash)
        }
}
