import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

// MARK: - CoreAPI.EncryptedTransactionMessage
extension CoreAPI {
	public struct EncryptedTransactionMessage: Codable, Hashable {
		public private(set) var type: TransactionMessageType
		/** The hex-encoded (128-bit) AES-GCM encrypted bytes of an SBOR-encoded `PlaintextTransactionMessage`. The bytes are serialized as the concatenation `Nonce/IV (12 bytes) || Cipher (variable length) || Tag/MAC (16 bytes)`:  */
		public private(set) var encryptedHex: String
		public private(set) var curveDecryptorSets: [EncryptedMessageCurveDecryptorSet]

		public init(type: TransactionMessageType, encryptedHex: String, curveDecryptorSets: [EncryptedMessageCurveDecryptorSet]) {
			self.type = type
			self.encryptedHex = encryptedHex
			self.curveDecryptorSets = curveDecryptorSets
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case type
			case encryptedHex = "encrypted_hex"
			case curveDecryptorSets = "curve_decryptor_sets"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(type, forKey: .type)
			try container.encode(encryptedHex, forKey: .encryptedHex)
			try container.encode(curveDecryptorSets, forKey: .curveDecryptorSets)
		}
	}
}
