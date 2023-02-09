import Tagged
import Prelude

enum DataChannelMessage: Codable, Sendable, Equatable {
        public typealias ID = Tagged<Self, String>

        case chunkedMessage(ChunkedMessage)
        case receipt(Receipt)

        enum ChunkedMessage: Codable, Sendable, Equatable  {
                case metaData(MetaDataPackage)
                case chunk(ChunkPackage)
        }

        enum Receipt: Codable, Sendable, Equatable  {
                case receiveMessageConfirmation(ReceiveConfirmation)
                case receiveMessageError(ReceiveError)
        }

        var receipt: Receipt? {
                guard case let .receipt(value) = self else {
                        return nil
                }
                return value
        }

        var chunkedMessage: ChunkedMessage? {
                guard case let .chunkedMessage(value) = self else {
                        return nil
                }
                return value
        }
}

extension DataChannelMessage.ChunkedMessage {
        struct MetaDataPackage: Sendable, Equatable, Codable {
                let messageId: DataChannelMessage.ID
                let chunkCount: Int
                let messageByteCount: Int
                let hashOfMessage: HexCodable
        }

        struct ChunkPackage: Sendable, Equatable, Codable {
                let messageId: DataChannelMessage.ID
                let chunkIndex: Int
                let chunkData: Data
        }

        var messageID: DataChannelMessage.ID {
                switch self {
                case let .metaData(metadata):
                        return metadata.messageId
                case let .chunk(chunk):
                        return chunk.messageId
                }
        }

        var metaData: MetaDataPackage? {
                guard case let .metaData(value) = self else {
                        return nil
                }
                return value
        }
}

extension DataChannelMessage.ChunkedMessage.ChunkPackage: Comparable {
        // Comparable so we can sort them conveniently if received unsorted.
        static func < (lhs: Self, rhs: Self) -> Bool {
                lhs.chunkIndex < rhs.chunkIndex
        }
}

extension DataChannelMessage.Receipt {
        struct ReceiveConfirmation: Sendable, Equatable, Codable {
                let messageId: DataChannelMessage.ID
        }

        struct ReceiveError: Sendable, Equatable, Codable, LocalizedError {
                enum Reason: String, Sendable, Codable {
                        case messageHashesMismatch
                }

                let messageId: DataChannelMessage.ID
                let error: Reason
        }

        var messageID: DataChannelMessage.ID {
                switch self {
                case let .receiveMessageConfirmation(confirmation):
                        return confirmation.messageId
                case let .receiveMessageError(error):
                        return error.messageId
                }
        }
}
