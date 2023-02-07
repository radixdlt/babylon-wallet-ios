import Foundation
import Prelude
import Tagged

// MARK: - RequestIdTag
enum RequestIdTag {}
typealias RequestID = Tagged<RequestIdTag, String>

// MARK: - EncryptedPayloadTag
enum EncryptedPayloadTag {}
typealias EncryptedPayload = Tagged<EncryptedPayloadTag, HexCodable>

// MARK: - SignalingServerConnectionIDTag
enum SignalingServerConnectionIDTag {}
typealias SignalingServerConnectionID = Tagged<SignalingServerConnectionIDTag, HexCodable32Bytes>

// MARK: - EncryptionKeyTag
enum EncryptionKeyTag {}
typealias EncryptionKey = Tagged<EncryptionKeyTag, HexCodable32Bytes>

// MARK: - SDPTag
enum SDPTag {}
typealias SDP = Tagged<SDPTag, String>

// MARK: - DataChannelIDTag
enum DataChannelIDTag {}
typealias DataChannelID = Tagged<DataChannelIDTag, Int32>
