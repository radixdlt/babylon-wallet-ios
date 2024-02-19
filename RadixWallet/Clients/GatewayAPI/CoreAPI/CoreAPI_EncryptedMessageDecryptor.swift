import Foundation

extension CoreAPI {
	public struct EncryptedMessageDecryptor: Codable, Hashable {
		/** The last 8 bytes of the Blake2b-256 hash of the public key bytes, in their standard Radix byte-serialization. */
		public private(set) var publicKeyFingerprintHex: String
		/** The hex-encoded wrapped key bytes from applying RFC 3394 (256-bit) AES-KeyWrap to the 128-bit message ephemeral public key, with the secret KEK provided by static Diffie-Helman between the decryptor public key, and the `dh_ephemeral_public_key` for that curve type. The bytes are serialized (according to RFC 3394) as the concatenation `IV (first 8 bytes) || Cipher (wrapped 128-bit key, encoded as two 64-bit blocks)`.  */
		public private(set) var aesWrappedKeyHex: String

		public init(publicKeyFingerprintHex: String, aesWrappedKeyHex: String) {
			self.publicKeyFingerprintHex = publicKeyFingerprintHex
			self.aesWrappedKeyHex = aesWrappedKeyHex
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case publicKeyFingerprintHex = "public_key_fingerprint_hex"
			case aesWrappedKeyHex = "aes_wrapped_key_hex"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(publicKeyFingerprintHex, forKey: .publicKeyFingerprintHex)
			try container.encode(aesWrappedKeyHex, forKey: .aesWrappedKeyHex)
		}
	}
}
