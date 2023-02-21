import Foundation

// MARK: - Engine.Signature
extension Engine {
	public enum Signature: Sendable, Codable, Hashable {
		// ==============
		// Enum Variants
		// ==============

		case ecdsaSecp256k1(EcdsaSecp256k1Signature)
		case eddsaEd25519(EddsaEd25519Signature)
	}
}

extension Engine.Signature {
	fileprivate var discriminator: CurveDiscriminator {
		switch self {
		case .ecdsaSecp256k1: return .ecdsaSecp256k1
		case .eddsaEd25519: return .eddsaEd25519
		}
	}
}

extension Engine.Signature {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case discriminator = "curve"
		case signature
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(discriminator, forKey: .discriminator)

		switch self {
		case let .ecdsaSecp256k1(signature):
			try container.encode(signature, forKey: .signature)
		case let .eddsaEd25519(signature):
			try container.encode(signature, forKey: .signature)
		}
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try container.decode(CurveDiscriminator.self, forKey: .discriminator)

		switch discriminator {
		case .ecdsaSecp256k1:
			self = .ecdsaSecp256k1(try container.decode(Engine.EcdsaSecp256k1Signature.self, forKey: .signature))
		case .eddsaEd25519:
			self = .eddsaEd25519(try container.decode(Engine.EddsaEd25519Signature.self, forKey: .signature))
		}
	}
}

extension Engine.Signature {
	public var bytes: [UInt8] {
		switch self {
		case let .ecdsaSecp256k1(signature):
			return signature.bytes
		case let .eddsaEd25519(signature):
			return signature.bytes
		}
	}

	public var hex: String {
		bytes.hex
	}
}
