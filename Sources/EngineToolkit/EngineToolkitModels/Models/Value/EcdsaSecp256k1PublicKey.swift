import Foundation

// MARK: - EcdsaSecp256k1PublicKey
public struct EcdsaSecp256k1PublicKey: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .ecdsaSecp256k1PublicKey
	public func embedValue() -> Value_ {
		.ecdsaSecp256k1PublicKey(self)
	}

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
		try container.encode(Self.kind, forKey: .type)

		try container.encode(bytes.hex(), forKey: .publicKey)
	}

	public init(from decoder: Decoder) throws {
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
