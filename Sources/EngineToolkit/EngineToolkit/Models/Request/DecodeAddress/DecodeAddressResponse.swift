import Foundation

// MARK: - DecodeAddressResponse
public struct DecodeAddressResponse: Sendable, Codable, Hashable {
	// MARK: Stored properties
	public let networkId: NetworkID
	public let networkName: String
	public let entityType: AddressKind
	public let data: [UInt8]
	public let hrp: String
	public let address: Address

	public init(
		networkName: String,
		entityType: AddressKind,
		data: [UInt8],
		hrp: String,
		address: Address,
		networkId: NetworkID
	) {
		self.networkId = networkId
		self.networkName = networkName
		self.entityType = entityType
		self.data = data
		self.hrp = hrp
		self.address = address
	}
}

// MARK: Codable
public extension DecodeAddressResponse {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case networkId = "network_id"
		case networkName = "network_name"
		case entityType = "entity_type"
		case data
		case hrp
		case address
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		try container.encode(networkId, forKey: .networkId)
		try container.encode(networkName, forKey: .networkName)
		try container.encode(entityType, forKey: .entityType)
		try container.encode(data.hex(), forKey: .data)
		try container.encode(hrp, forKey: .hrp)
		try container.encode(address, forKey: .address)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)

		try self.init(
			networkName: container.decode(String.self, forKey: .networkName),
			entityType: container.decode(AddressKind.self, forKey: .entityType),
			data: [UInt8](hex: container.decode(String.self, forKey: .data)),
			hrp: container.decode(String.self, forKey: .hrp),
			address: container.decode(Address.self, forKey: .address),
			networkId: container.decode(NetworkID.self, forKey: .networkId)
		)
	}
}
