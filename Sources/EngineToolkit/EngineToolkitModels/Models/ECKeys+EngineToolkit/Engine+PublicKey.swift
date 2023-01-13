import Cryptography
import Prelude

// MARK: - Engine.PublicKey
public extension Engine {
	enum PublicKey: Sendable, Codable, Hashable {
		// ==============
		// Enum Variants
		// ==============
		case ecdsaSecp256k1(EcdsaSecp256k1PublicKey)
		case eddsaEd25519(EddsaEd25519PublicKey)
	}
}

public extension Engine.PublicKey {
	func isValidSignature(
		_ engineSignature: Engine.Signature,
		for message: any DataProtocol
	) throws -> Bool {
		try SLIP10.PublicKey(engine: self)
			.isValidSignature(
				SLIP10.Signature(engine: engineSignature),
				for: message
			)
	}
}

public extension Engine.PublicKey {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case discriminator = "type"
		case publicKey = "public_key"
	}

	internal var discriminator: CurveDiscriminator {
		switch self {
		case .ecdsaSecp256k1: return .ecdsaSecp256k1
		case .eddsaEd25519: return .eddsaEd25519
		}
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
		case let .ecdsaSecp256k1(publicKey):
			try container.encode(discriminator, forKey: .discriminator)
			try container.encode(publicKey, forKey: .publicKey)
		case let .eddsaEd25519(publicKey):
			try container.encode(discriminator, forKey: .discriminator)
			try container.encode(publicKey, forKey: .publicKey)
		}
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try container.decode(CurveDiscriminator.self, forKey: .discriminator)

		switch discriminator {
		case .ecdsaSecp256k1:
			self = .ecdsaSecp256k1(try container.decode(Engine.EcdsaSecp256k1PublicKey.self, forKey: .publicKey))
		case .eddsaEd25519:
			self = .eddsaEd25519(try container.decode(Engine.EddsaEd25519PublicKey.self, forKey: .publicKey))
		}
	}
}

public extension Engine.PublicKey {
	/// For ECDSA secp256k1 public keys this will use the compressed representation
	/// For EdDSA Curve25519 there is no difference between compressed and uncompressed.
	var compressedRepresentation: Data {
		try! SLIP10.PublicKey(engine: self).compressedRepresentation
	}

	/// For ECDSA secp256k1 public keys this will use the uncompressed representation
	/// For EdDSA Curve25519 there is no difference between compressed and uncompressed.
	var uncompressedRepresentation: Data {
		try! SLIP10.PublicKey(engine: self).uncompressedRepresentation
	}
}
