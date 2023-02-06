import Foundation
import Tagged
import Prelude

// MARK: - RequestIdTag
enum RequestIdTag {}
typealias RequestID = Tagged<RequestIdTag, String>

// MARK: - EncryptedPayloadTag
enum EncryptedPayloadTag {}
typealias EncryptedPayload = Tagged<EncryptedPayloadTag, HexCodable>

enum SignalingServerConnectionIDTag {}
typealias SignalingServerConnectionID = Tagged<SignalingServerConnectionIDTag, HexCodable32Bytes>

enum EncryptionKeyTag {}
typealias EncryptionKey = Tagged<EncryptionKeyTag, HexCodable32Bytes>

enum SDPTag {}
typealias SDP = Tagged<SDPTag, String>

enum DataChannelIDTag {}
typealias DataChannelID = Tagged<DataChannelIDTag, Int32>
