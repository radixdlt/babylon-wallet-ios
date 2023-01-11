import Foundation

// MARK: - Engine.EddsaEd25519Signature
public extension Engine {
	struct EddsaEd25519Signature: Sendable, Codable, Hashable {
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
}

public extension Engine.EddsaEd25519Signature {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case value, type
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container: SingleValueEncodingContainer = encoder.singleValueContainer()
		try container.encode(bytes.hex())
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		try self.init(hex: container.decode(String.self))
	}
}
