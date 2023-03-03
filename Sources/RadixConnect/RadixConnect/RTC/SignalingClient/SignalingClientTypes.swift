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
	private var symmetric: SymmetricKey {
		.init(data: self.data.data)
	}

	func decrypt(data: Data) throws -> Data {
		try AES.GCM.open(
			AES.GCM.SealedBox(combined: data),
			using: symmetric
		)
	}

	func encrypt(data: Data) throws -> Data {
		try AES.GCM
			.seal(data, using: symmetric)
			.combined!
	}
}

// MARK: - SDPTag
enum SDPTag {}
typealias SDP = Tagged<SDPTag, String>
