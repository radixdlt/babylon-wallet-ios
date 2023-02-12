// MARK: - DeriveVirtualIdentityAddressRequest
public struct DeriveVirtualIdentityAddressRequest: Sendable, Codable, Hashable {
	public let publicKey: Engine.PublicKey
	public let networkId: NetworkID

	public init(
		publicKey: Engine.PublicKey,
		networkId: NetworkID
	) {
		self.publicKey = publicKey
		self.networkId = networkId
	}
}

extension DeriveVirtualIdentityAddressRequest {
	private enum CodingKeys: String, CodingKey {
		case publicKey = "public_key"
		case networkId = "network_id"
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(publicKey, forKey: .publicKey)
		try container.encode(String(networkId), forKey: .networkId)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let publicKey = try container.decode(Engine.PublicKey.self, forKey: .publicKey)
		let networkId: UInt8 = try decodeAndConvertToNumericType(container: container, key: .networkId)
		self.init(publicKey: publicKey, networkId: NetworkID(networkId))
	}
}

// MARK: - DeriveVirtualIdentityAddressResponse
public struct DeriveVirtualIdentityAddressResponse: Sendable, Codable, Hashable {
	public let virtualIdentityAddress: ComponentAddress

	public init(
		virtualIdentityAddress: ComponentAddress
	) {
		self.virtualIdentityAddress = virtualIdentityAddress
	}

	private enum CodingKeys: String, CodingKey {
		case virtualIdentityAddress = "virtual_identity_address"
	}
}
