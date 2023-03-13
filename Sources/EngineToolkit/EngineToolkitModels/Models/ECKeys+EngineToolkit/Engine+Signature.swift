import Foundation

// MARK: - Engine.Signature
extension Engine {
	public enum Signature: Sendable, Codable, Hashable {
		// ==============
		// Enum Variants
		// ==============

		case ecdsaSecp256k1(ECPrimitive)
		case eddsaEd25519(ECPrimitive)
	}
}

extension Engine.Signature {
	fileprivate var discriminator: CurveDiscriminator {
		switch self {
		case .ecdsaSecp256k1: return .ecdsaSecp256k1
		case .eddsaEd25519: return .eddsaEd25519
		}
	}

	fileprivate var primitive: Engine.ECPrimitive {
		switch self {
		case let .ecdsaSecp256k1(primitive), let .eddsaEd25519(primitive):
			return primitive
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
		let primitive = try container.decode(Engine.ECPrimitive.self, forKey: .signature)

		switch discriminator {
		case .ecdsaSecp256k1:
			self = .ecdsaSecp256k1(primitive)
		case .eddsaEd25519:
			self = .eddsaEd25519(primitive)
		}
	}
}

extension Engine.Signature {
	public var bytes: [UInt8] {
		primitive.bytes
	}

	public var hex: String {
		bytes.hex
	}
}
