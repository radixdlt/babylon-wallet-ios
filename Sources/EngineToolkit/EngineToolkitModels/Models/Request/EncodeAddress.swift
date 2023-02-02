// MARK: - EncodeAddressRequest
public struct EncodeAddressRequest: Sendable, Codable, Hashable {
	// MARK: Stored properties

	public let addressBytes: [UInt8]
	public let networkId: NetworkID

	// MARK: Init

	public init(addressBytes: [UInt8], networkId: NetworkID) {
		self.addressBytes = addressBytes
		self.networkId = networkId
	}

	public init(addressHex: String, networkId: NetworkID) throws {
		self.init(
			addressBytes: try [UInt8](hex: addressHex),
			networkId: networkId
		)
	}
}

public extension EncodeAddressRequest {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case addressBytes = "address_bytes"
		case networkId = "network_id"
	}

	// MARK: Codable

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(addressBytes.hex(), forKey: .addressBytes)
		try container.encode(String(networkId), forKey: .networkId)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)

		try self.init(
			addressHex: container.decode(String.self, forKey: .addressBytes),
			networkId: NetworkID(decodeAndConvertToNumericType(container: container, key: .networkId))
		)
	}
}

public typealias EncodeAddressResponse = Address
