import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.PublicKeyEcdsaSecp256k1")
public typealias PublicKeyEcdsaSecp256k1 = GatewayAPI.PublicKeyEcdsaSecp256k1

// MARK: - GatewayAPI.PublicKeyEcdsaSecp256k1
extension GatewayAPI {
	public struct PublicKeyEcdsaSecp256k1: Codable, Hashable {
		public private(set) var keyType: PublicKeyType
		/** The hex-encoded compressed ECDSA Secp256k1 public key (33 bytes) */
		public private(set) var keyHex: String

		public init(keyType: PublicKeyType, keyHex: String) {
			self.keyType = keyType
			self.keyHex = keyHex
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case keyType = "key_type"
			case keyHex = "key_hex"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(keyType, forKey: .keyType)
			try container.encode(keyHex, forKey: .keyHex)
		}
	}
}
