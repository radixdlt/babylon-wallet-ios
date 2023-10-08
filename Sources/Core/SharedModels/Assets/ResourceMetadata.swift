import EngineKit

// MARK: - ResourceMetadata
public struct ResourceMetadata: Sendable, Hashable, Codable {
	public let name: String?
	public let symbol: String?
	public let description: String?
	public let iconURL: URL?
	public let tags: [AssetTag]
	public let dappDefinitions: [AccountAddress]?
	public let dappDefinition: AccountAddress?
	public let validator: ValidatorAddress?
	public let poolUnit: ResourcePoolAddress?
	public let poolUnitResource: ResourceAddress?
	public let claimedEntities: [String]?
	public let claimedWebsites: [URL]?
	public let accountType: AccountType?

	public init(
		name: String? = nil,
		symbol: String? = nil,
		description: String? = nil,
		iconURL: URL? = nil,
		tags: [AssetTag] = [],
		dappDefinitions: [AccountAddress]? = nil,
		dappDefinition: AccountAddress? = nil,
		validator: ValidatorAddress? = nil,
		poolUnit: ResourcePoolAddress? = nil,
		poolUnitResource: ResourceAddress? = nil,
		claimedEntities: [String]? = nil,
		claimedWebsites: [URL]? = nil,
		accountType: AccountType? = nil
	) {
		self.name = name
		self.symbol = symbol
		self.description = description
		self.iconURL = iconURL
		self.tags = tags
		self.dappDefinitions = dappDefinitions
		self.dappDefinition = dappDefinition
		self.validator = validator
		self.poolUnit = poolUnit
		self.poolUnitResource = poolUnitResource
		self.claimedEntities = claimedEntities
		self.claimedWebsites = claimedWebsites
		self.accountType = accountType
	}
}

// MARK: - AccountType
public enum AccountType: String, Sendable, Codable {
	case dappDefinition = "dapp definition"
}
