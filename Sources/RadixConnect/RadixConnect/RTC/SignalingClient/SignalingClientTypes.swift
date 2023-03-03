import Foundation
import Prelude
import Tagged

extension SignalingClient {
	// MARK: - EncryptionKeyTag
	enum EncryptionKeyTag {}
	typealias EncryptionKey = Tagged<EncryptionKeyTag, HexCodable32Bytes>
}

// MARK: - SDPTag
enum SDPTag {}
typealias SDP = Tagged<SDPTag, String>
