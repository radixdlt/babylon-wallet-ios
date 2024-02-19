import Foundation

extension CoreAPI {
	/** A decryptor set for a particular ECDSA curve type. The (128-bit) AES-GCM symmetric key is encrypted separately for each decryptor public key via (256-bit) AES-KeyWrap. AES-KeyWrap uses a key derived via a KDF (Key Derivation Function) using a shared secret. For each decryptor public key, we create a shared curve point &#x60;G&#x60; via static Diffie-Helman between the decryptor public key, and a per-transaction ephemeral public key for that curve type. We then use that shared secret with a key derivation function to create the (256-bit) KEK (Key Encrypting Key): &#x60;KEK &#x3D; HKDF(hash: Blake2b, secret: x co-ord of G, salt: [], length: 256 bits)&#x60;.  */
	public struct EncryptedMessageCurveDecryptorSet: Codable, Hashable {
		/** The ephemeral Diffie-Helman public key for a particular ECDSA curve type (see its `key_type`). */
		public private(set) var dhEphemeralPublicKey: PublicKey
		public private(set) var decryptors: [EncryptedMessageDecryptor]

		public init(dhEphemeralPublicKey: PublicKey, decryptors: [EncryptedMessageDecryptor]) {
			self.dhEphemeralPublicKey = dhEphemeralPublicKey
			self.decryptors = decryptors
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case dhEphemeralPublicKey = "dh_ephemeral_public_key"
			case decryptors
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(dhEphemeralPublicKey, forKey: .dhEphemeralPublicKey)
			try container.encode(decryptors, forKey: .decryptors)
		}
	}
}
