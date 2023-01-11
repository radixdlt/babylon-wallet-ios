import Foundation

// MARK: - Engine.SignatureWithPublicKey
public extension Engine {
	enum SignatureWithPublicKey: Sendable, Codable, Hashable {
		// ==============
		// Enum Variants
		// ==============

		case ecdsaSecp256k1(
			signature: EcdsaSecp256k1Signature
		)

		case eddsaEd25519(
			signature: EddsaEd25519Signature,
			publicKey: EddsaEd25519PublicKey
		)
	}
}

public extension Engine.SignatureWithPublicKey {
	var signature: Engine.Signature {
		switch self {
		case let .eddsaEd25519(signature, _):
			return .eddsaEd25519(signature)
		case let .ecdsaSecp256k1(signature):
			return .ecdsaSecp256k1(signature)
		}
	}

	var publicKey: Engine.PublicKey? {
		switch self {
		case let .eddsaEd25519(_, publicKey):
			return .eddsaEd25519(publicKey)
		case .ecdsaSecp256k1:
			return nil
		}
	}
}

private extension Engine.SignatureWithPublicKey {
	var discriminator: CurveDiscriminator {
		switch self {
		case .ecdsaSecp256k1: return .ecdsaSecp256k1
		case .eddsaEd25519: return .eddsaEd25519
		}
	}
}

public extension Engine.SignatureWithPublicKey {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case discriminator = "type"
		case publicKey = "public_key"
		case signature
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(discriminator, forKey: .discriminator)

		switch self {
		case let .ecdsaSecp256k1(signature):
			try container.encode(signature, forKey: .signature)
		case let .eddsaEd25519(signature, publicKey):
			try container.encode(signature, forKey: .signature)
			try container.encode(publicKey, forKey: .publicKey)
		}
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try container.decode(CurveDiscriminator.self, forKey: .discriminator)

		switch discriminator {
		case .ecdsaSecp256k1:
			self = .ecdsaSecp256k1(
				signature: try container.decode(Engine.EcdsaSecp256k1Signature.self, forKey: .signature)
			)
		case .eddsaEd25519:
			self = .eddsaEd25519(
				signature: try container.decode(Engine.EddsaEd25519Signature.self, forKey: .signature),
				publicKey: try container.decode(Engine.EddsaEd25519PublicKey.self, forKey: .publicKey)
			)
		}
	}
}
