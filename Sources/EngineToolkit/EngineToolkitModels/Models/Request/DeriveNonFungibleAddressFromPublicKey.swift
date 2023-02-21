// MARK: - DeriveNonFungibleGlobalIdFromPublicKeyRequest
public struct DeriveNonFungibleGlobalIdFromPublicKeyRequest: Sendable, Codable, Hashable {
	// MARK: Stored properties

	public let publicKey: Engine.PublicKey
	public let networkId: NetworkID

	// MARK: Init

	public init(publicKey: Engine.PublicKey, networkId: NetworkID) {
		self.publicKey = publicKey
		self.networkId = networkId
	}
}

extension DeriveNonFungibleGlobalIdFromPublicKeyRequest {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case publicKey = "public_key"
		case networkId = "network_id"
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(String(networkId), forKey: .networkId)
		try container.encode(publicKey, forKey: .publicKey)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		try self.init(
			publicKey: container.decode(Engine.PublicKey.self, forKey: .publicKey),
			networkId: NetworkID(decodeAndConvertToNumericType(container: container, key: .networkId))
		)
	}
}

// MARK: - DeriveNonFungibleGlobalIdFromPublicKeyResponse
public struct DeriveNonFungibleGlobalIdFromPublicKeyResponse: Sendable, Codable, Hashable {
	public let nonFungibleGlobalId: NonFungibleGlobalId

	public init(nonFungibleGlobalId: NonFungibleGlobalId) {
		self.nonFungibleGlobalId = nonFungibleGlobalId
	}
}

extension DeriveNonFungibleGlobalIdFromPublicKeyResponse {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(nonFungibleGlobalId)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		try self.init(nonFungibleGlobalId: container.decode(NonFungibleGlobalId.self))
	}
}
