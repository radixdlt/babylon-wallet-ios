// MARK: - DeriveNonFungibleAddressFromPublicKeyRequest
public struct DeriveNonFungibleAddressFromPublicKeyRequest: Sendable, Codable, Hashable {
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

// MARK: - DeriveNonFungibleAddressFromPublicKeyResponse
public struct DeriveNonFungibleAddressFromPublicKeyResponse: Sendable, Codable, Hashable {
	// MARK: Stored properties
	public let nonFungibleAddress: NonFungibleAddress

	// MARK: Init
	public init(nonFungibleAddress: NonFungibleAddress) {
		self.nonFungibleAddress = nonFungibleAddress
	}

	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case nonFungibleAddress = "non_fungible_address"
	}
}
