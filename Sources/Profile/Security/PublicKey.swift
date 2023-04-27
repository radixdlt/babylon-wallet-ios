import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - SLIP10.PublicKey + Codable
extension SLIP10.PublicKey: Codable {}
extension SLIP10.PublicKey {
	private enum CodingKeys: String, CodingKey {
		case curve, compressedData
	}

	public var curve: SLIP10.Curve {
		switch self {
		case .eddsaEd25519: return .curve25519
		case .ecdsaSecp256k1: return .secp256k1
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(curve, forKey: .curve)
		try container.encode(HexCodable(data: compressedData), forKey: .compressedData)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let curve = try container.decode(SLIP10.Curve.self, forKey: .curve)
		let hexCodable = try container.decode(HexCodable.self, forKey: .compressedData)

		switch curve {
		case .curve25519:
			self = try .eddsaEd25519(.init(compressedRepresentation: hexCodable.data))
		case .secp256k1:
			self = try .ecdsaSecp256k1(.init(compressedRepresentation: hexCodable.data))
		}
	}
}

extension SLIP10.PublicKey {
	public var compressedData: Data {
		switch self {
		case let .eddsaEd25519(key): return key.compressedRepresentation
		case let .ecdsaSecp256k1(key): return key.compressedRepresentation
		}
	}
}
