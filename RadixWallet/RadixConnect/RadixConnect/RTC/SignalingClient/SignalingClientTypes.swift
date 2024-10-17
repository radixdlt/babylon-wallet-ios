import CryptoKit
import Tagged
import WebRTC

extension SignalingClient {
	// MARK: - EncryptionKeyTag
	enum EncryptionKeyTag {}
	typealias EncryptionKey = Tagged<EncryptionKeyTag, Exactly32Bytes>

	enum ClientSource: String, Sendable, Codable, Equatable {
		case wallet
		case `extension`
	}
}

extension SignalingClient.EncryptionKey {
	var symmetric: SymmetricKey {
		.init(data: self.data.data)
	}
}
