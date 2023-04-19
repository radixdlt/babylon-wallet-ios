import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.PublicKeyEcdsaSecp256k1AllOf")
public typealias PublicKeyEcdsaSecp256k1AllOf = GatewayAPI.PublicKeyEcdsaSecp256k1AllOf

// MARK: - GatewayAPI.PublicKeyEcdsaSecp256k1AllOf
extension GatewayAPI {
	public struct PublicKeyEcdsaSecp256k1AllOf: Codable, Hashable {
		/** The hex-encoded compressed ECDSA Secp256k1 public key (33 bytes) */
		public private(set) var keyHex: String

		public init(keyHex: String) {
			self.keyHex = keyHex
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case keyHex = "key_hex"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(keyHex, forKey: .keyHex)
		}
	}
}
