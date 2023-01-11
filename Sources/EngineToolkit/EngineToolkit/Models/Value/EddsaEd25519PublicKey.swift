import Foundation

// MARK: - EddsaEd25519PublicKey
public struct EddsaEd25519PublicKey: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .eddsaEd25519PublicKey
	public func embedValue() -> Value_ {
		.eddsaEd25519PublicKey(self)
	}

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

public extension EddsaEd25519PublicKey {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case publicKey = "public_key", type
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(bytes.hex(), forKey: .publicKey)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ValueKind = try container.decode(ValueKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		// Decoding `publicKey`
		try self.init(hex: container.decode(String.self, forKey: .publicKey))
	}
}
