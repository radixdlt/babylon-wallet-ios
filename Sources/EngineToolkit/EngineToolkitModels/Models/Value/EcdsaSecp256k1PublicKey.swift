import Foundation

// MARK: - EcdsaSecp256k1PublicKey
public struct EcdsaSecp256k1PublicKey: Sendable, Codable, Hashable {
	// Curve name and key type, used as a discriminators
	public static let curve: CurveDiscriminator = .ecdsaSecp256k1
	public static let kind: ECPrimitiveKind = .publicKey

	// MARK: Stored properties
	public let bytes: [UInt8]

	// MARK: Init

	public init(bytes: [UInt8]) {
		self.bytes = bytes
	}

	public init(hex: String) throws {
		try self.init(bytes: [UInt8](hex: hex))
	}
}

extension EcdsaSecp256k1PublicKey {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case publicKey = "public_key", type
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.curve.rawValue + Self.kind.rawValue, forKey: .type)
		try container.encode(bytes.hex(), forKey: .publicKey)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let type = try container.decode(String.self, forKey: .type)
		try type.confirmCurveDiscriminator(curve: Self.curve, kind: Self.kind)

		// Decoding `publicKey`
		try self.init(hex: container.decode(String.self, forKey: .publicKey))
	}
}
