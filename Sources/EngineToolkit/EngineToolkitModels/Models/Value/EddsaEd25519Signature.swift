import Foundation

// MARK: - EddsaEd25519Signature
public struct EddsaEd25519Signature: Sendable, Codable, Hashable {
	// Curve name and key type, used as a discriminators
	public static let curve: CurveDiscriminator = .eddsaEd25519
	public static let kind: ECPrimitiveKind = .signature

	// MARK: Stored properties
	public let bytes: [UInt8]

	// MARK: Init

	public init(bytes: [UInt8]) {
		self.bytes = bytes
	}

	public init(hex: String) throws {
		// TODO: Validation of length of array
		try self.init(bytes: [UInt8](hex: hex))
	}
}

extension EddsaEd25519Signature {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case signature, type
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.curve.rawValue + Self.kind.rawValue, forKey: .type)
		try container.encode(bytes.hex(), forKey: .signature)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let type = try container.decode(String.self, forKey: .type)
		try type.confirmCurveDiscriminator(curve: Self.curve, kind: Self.kind)

		// Decoding `signature`
		try self.init(hex: container.decode(String.self, forKey: .signature))
	}
}
