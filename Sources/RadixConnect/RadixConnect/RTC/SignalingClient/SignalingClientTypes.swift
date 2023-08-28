import Foundation
import Prelude
import Tagged

extension SignalingClient {
	// MARK: - EncryptionKeyTag
	enum EncryptionKeyTag {}
	typealias EncryptionKey = Tagged<EncryptionKeyTag, HexCodable32Bytes>

	enum ClientSource: String, Sendable, Codable, Equatable {
		case wallet
		case `extension`
	}
}

import CryptoKit
extension SignalingClient.EncryptionKey {
	public var symmetric: SymmetricKey {
		.init(data: self.data.data)
	}
}
