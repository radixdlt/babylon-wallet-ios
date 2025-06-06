#if canImport(AnyCodable)
#endif

// MARK: - GatewayAPI.PublicKeyHash
extension GatewayAPI {
	enum PublicKeyHash: Codable, Hashable {
		case ecdsaSecp256k1(PublicKeyHashEcdsaSecp256k1)
		case eddsaEd25519(PublicKeyHashEddsaEd25519)

		enum CodingKeys: String, CodingKey, CaseIterable {
			case keyType = "key_hash_type"
		}

		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let type = try container.decode(PublicKeyType.self, forKey: .keyType)

			switch type {
			case .ecdsaSecp256k1:
				self = try .ecdsaSecp256k1(.init(from: decoder))
			case .eddsaEd25519:
				self = try .eddsaEd25519(.init(from: decoder))
			}
		}

		func encode(to encoder: Encoder) throws {
			switch self {
			case let .ecdsaSecp256k1(key):
				try key.encode(to: encoder)
			case let .eddsaEd25519(key):
				try key.encode(to: encoder)
			}
		}
	}
}
