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
		try self.init(
			addressBytes: [UInt8](hex: addressHex),
			networkId: networkId
		)
	}
}

extension EncodeAddressRequest {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case addressBytes = "address_bytes"
		case networkId = "network_id"
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(addressBytes.hex(), forKey: .addressBytes)
		try container.encode(String(networkId), forKey: .networkId)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)

		try self.init(
			addressHex: container.decode(String.self, forKey: .addressBytes),
			networkId: NetworkID(decodeAndConvertToNumericType(container: container, key: .networkId))
		)
	}
}

public typealias EncodeAddressResponse = Address
