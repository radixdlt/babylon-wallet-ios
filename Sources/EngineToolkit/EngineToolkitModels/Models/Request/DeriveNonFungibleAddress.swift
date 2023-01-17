// MARK: - DeriveNonFungibleAddressRequest
public struct DeriveNonFungibleAddressRequest: Sendable, Codable, Hashable {
	// MARK: Stored properties
	public let resourceAddress: ResourceAddress
	public let nonFungibleId: NonFungibleId

	// MARK: Init
	public init(resourceAddress: ResourceAddress, nonFungibleId: NonFungibleId) {
		self.resourceAddress = resourceAddress
		self.nonFungibleId = nonFungibleId
	}

	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case resourceAddress = "resource_address"
		case nonFungibleId = "non_fungible_id"
	}
}

// MARK: - DeriveNonFungibleAddressResponse
public struct DeriveNonFungibleAddressResponse: Sendable, Codable, Hashable {
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
