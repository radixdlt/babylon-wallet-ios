// MARK: - SborDecodeRequest
public struct SborDecodeRequest: Sendable, Codable, Hashable {
	// MARK: Stored properties
	public let encodedValue: [UInt8]
	public let networkId: NetworkID

	// MARK: Init

	public init(encodedBytes: [UInt8], networkId: NetworkID) {
		self.encodedValue = encodedBytes
		self.networkId = networkId
	}

	public init(encodedHex: String, networkId: NetworkID) throws {
		self.init(encodedBytes: try [UInt8](hex: encodedHex), networkId: networkId)
	}
}

public extension SborDecodeRequest {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case encodedValue = "encoded_value"
		case networkId = "network_id"
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(encodedValue.hex(), forKey: .encodedValue)
		try container.encode(networkId, forKey: .networkId)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)

		try self.init(
			encodedHex: container.decode(String.self, forKey: .encodedValue),
			networkId: container.decode(NetworkID.self, forKey: .networkId)
		)
	}
}

public typealias SborDecodeResponse = Value_
