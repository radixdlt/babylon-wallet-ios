import Cryptography
import Prelude

// MARK: - Engine.PublicKey
extension Engine {
	public enum PublicKey: Sendable, Codable, Hashable {
		// ==============
		// Enum Variants
		// ==============
		case ecdsaSecp256k1(ECPrimitive)
		case eddsaEd25519(ECPrimitive)
	}
}

extension Engine.PublicKey {
	public func isValidSignature(
		_ engineSignature: Engine.Signature,
		for message: some DataProtocol
	) throws -> Bool {
		try SLIP10.PublicKey(engine: self)
			.isValidSignature(
				SLIP10.Signature(engine: engineSignature),
				for: message
			)
	}
}

extension Engine.PublicKey {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case discriminator = "curve"
		case publicKey = "public_key"
	}

	var discriminator: CurveDiscriminator {
		switch self {
		case .ecdsaSecp256k1: return .ecdsaSecp256k1
		case .eddsaEd25519: return .eddsaEd25519
		}
	}

	var primitive: Engine.ECPrimitive {
		switch self {
		case let .ecdsaSecp256k1(primitive), let .eddsaEd25519(primitive):
			return primitive
		}
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(discriminator, forKey: .discriminator)
		try container.encode(primitive, forKey: .publicKey)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try container.decode(CurveDiscriminator.self, forKey: .discriminator)
		let primitive = try container.decode(Engine.ECPrimitive.self, forKey: .publicKey)

		switch discriminator {
		case .ecdsaSecp256k1:
			self = .ecdsaSecp256k1(primitive)
		case .eddsaEd25519:
			self = .eddsaEd25519(primitive)
		}
	}
}

extension Engine.PublicKey {
	/// For ECDSA secp256k1 public keys this will use the compressed representation
	/// For EdDSA Curve25519 there is no difference between compressed and uncompressed.
	public var compressedRepresentation: Data {
		try! SLIP10.PublicKey(engine: self).compressedRepresentation
	}

	/// For ECDSA secp256k1 public keys this will use the uncompressed representation
	/// For EdDSA Curve25519 there is no difference between compressed and uncompressed.
	public var uncompressedRepresentation: Data {
		try! SLIP10.PublicKey(engine: self).uncompressedRepresentation
	}
}
