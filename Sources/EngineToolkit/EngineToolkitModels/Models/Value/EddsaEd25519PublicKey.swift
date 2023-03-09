import Foundation

// MARK: - EddsaEd25519PublicKey
public struct EddsaEd25519PublicKey: Sendable, Codable, Hashable {
	// Curve name and key type, used as a discriminators
	public static let curve: CurveDiscriminator = .eddsaEd25519
	public static let keyType: CurveKeyType = .publicKey

	// MARK: Stored properties
	public let bytes: [UInt8]

	// MARK: Init

	public init(bytes: [UInt8]) {
		self.bytes = bytes
	}

	public init(hex: String) throws {
		// TODO: Validation of length of array
		try self.init(bytes: .init(hex: hex))
	}
}

extension EddsaEd25519PublicKey {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case publicKey = "public_key", type
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.curve, forKey: .type)
		try container.encode(bytes.hex(), forKey: .publicKey)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let type = try container.decode(String.self, forKey: .type)
		try type.confirmCurveDiscriminator(curve: Self.curve, keyType: Self.keyType)

		// Decoding `publicKey`
		try self.init(hex: container.decode(String.self, forKey: .publicKey))
	}
}
