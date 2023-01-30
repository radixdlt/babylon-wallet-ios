// MARK: - DeriveNonFungibleGlobalIdRequest
public struct DeriveNonFungibleGlobalIdRequest: Sendable, Codable, Hashable {
	// MARK: Stored properties
	public let resourceAddress: ResourceAddress
	public let nonFungibleLocalId: NonFungibleLocalId

	// MARK: Init
	public init(resourceAddress: ResourceAddress, nonFungibleLocalId: NonFungibleLocalId) {
		self.resourceAddress = resourceAddress
		self.nonFungibleLocalId = nonFungibleLocalId
	}

	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case resourceAddress = "resource_address"
		case nonFungibleLocalId = "non_fungible_id"
	}
}

// MARK: - DeriveNonFungibleGlobalIdResponse
public struct DeriveNonFungibleGlobalIdResponse: Sendable, Codable, Hashable {
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
