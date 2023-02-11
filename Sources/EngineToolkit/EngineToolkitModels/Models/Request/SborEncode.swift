public typealias SborEncodeRequest = Value_

// MARK: - SborEncodeResponse
public struct SborEncodeResponse: Sendable, Codable, Hashable {
	// MARK: Stored properties
	public let encodedValue: [UInt8]

	// MARK: Init

	public init(bytes: [UInt8]) {
		self.encodedValue = bytes
	}

	public init(hex: String) throws {
		self.init(bytes: try [UInt8](hex: hex))
	}
}

extension SborEncodeResponse {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case encodedValue = "encoded_value"
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(encodedValue.hex(), forKey: .encodedValue)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)

		try self.init(hex: container.decode(String.self, forKey: .encodedValue))
	}
}
