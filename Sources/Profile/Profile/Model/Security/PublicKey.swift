import Bite
import CryptoKit
import EngineToolkit
import Foundation
import SLIP10

// MARK: - ECCurve
public enum ECCurve: String, Codable {
	case curve25519
	case secp256k1
}

// MARK: - PublicKey + Codable
extension PublicKey: Codable {}
public extension PublicKey {
	private enum CodingKeys: String, CodingKey {
		case curve, compressedData
	}

	var curve: ECCurve {
		switch self {
		case .eddsaEd25519: return .curve25519
		case .ecdsaSecp256k1: return .secp256k1
		}
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(curve, forKey: .curve)
		try container.encode(HexCodable(data: compressedData), forKey: .compressedData)
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let curve = try container.decode(ECCurve.self, forKey: .curve)
		let hexCodable = try container.decode(HexCodable.self, forKey: .compressedData)

		switch curve {
		case .curve25519:
			self = try .eddsaEd25519(.init(compressedRepresentation: hexCodable.data))
		case .secp256k1:
			self = try .ecdsaSecp256k1(.init(compressedRepresentation: hexCodable.data))
		}
	}
}

public extension PublicKey {
	var compressedData: Data {
		switch self {
		case let .eddsaEd25519(key): return key.compressedRepresentation
		case let .ecdsaSecp256k1(key): return key.compressedRepresentation
		}
	}
}
