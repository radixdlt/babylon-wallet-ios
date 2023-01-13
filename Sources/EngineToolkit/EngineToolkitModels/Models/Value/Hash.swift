import Foundation

// MARK: - Hash
public struct Hash: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .hash
	public func embedValue() -> Value_ {
		.hash(self)
	}

	// MARK: Stored properties
	public let bytes: [UInt8]

	// MARK: Init

	public init(bytes: [UInt8]) {
		self.bytes = bytes
	}

	public init(hex: String) throws {
		// TODO: Validation of length of Hash
		self.init(bytes: try [UInt8](hex: hex))
	}
}

public extension Hash {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case value, type
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(bytes.hex(), forKey: .value)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ValueKind = try container.decode(ValueKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		// Decoding `value`
		try self.init(hex: container.decode(String.self, forKey: .value))
	}
}
