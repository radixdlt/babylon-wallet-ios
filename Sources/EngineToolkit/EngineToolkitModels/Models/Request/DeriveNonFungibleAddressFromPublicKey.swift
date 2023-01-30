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

	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case publicKey = "public_key"
		case networkId = "network_id"
	}
}

// MARK: - DeriveNonFungibleGlobalIdFromPublicKeyResponse
public struct DeriveNonFungibleGlobalIdFromPublicKeyResponse: Sendable, Codable, Hashable {
	// MARK: Stored properties
	public let nonFungibleGlobalId: NonFungibleGlobalId

	// MARK: Init
	public init(nonFungibleGlobalId: NonFungibleGlobalId) {
		self.nonFungibleGlobalId = nonFungibleGlobalId
	}

	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case nonFungibleGlobalId = "non_fungible_address"
	}
}
