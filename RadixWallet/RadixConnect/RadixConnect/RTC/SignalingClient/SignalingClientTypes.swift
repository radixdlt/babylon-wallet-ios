import WebRTCimport WebRTCimport WebRTC
extension SignalingClient {
	// MARK: - EncryptionKeyTag
	enum EncryptionKeyTag {}
	typealias EncryptionKey = Tagged<EncryptionKeyTag, HexCodable32Bytes>

	enum ClientSource: String, Sendable, Codable, Equatable {
		case wallet
		case `extension`
	}
}

import WebRTCextension SignalingClient.EncryptionKey {
	public var symmetric: SymmetricKey {
		.init(data: self.data.data)
	}
}
