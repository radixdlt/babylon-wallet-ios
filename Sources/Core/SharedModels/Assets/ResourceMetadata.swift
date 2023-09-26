public struct ResourceMetadata: Sendable, Hashable, Codable {
	public let name: String?
	public let symbol: String?
	public let description: String?
	public let iconURL: URL?
	public let tags: [AssetTag]
	public let dappDefinitions: [DappDefinitionAddress]?

	public init(
		name: String? = nil,
		symbol: String? = nil,
		description: String? = nil,
		iconURL: URL? = nil,
		tags: [AssetTag] = [],
		dappDefinitions: [DappDefinitionAddress]? = nil
	) {
		self.name = name
		self.symbol = symbol
		self.description = description
		self.iconURL = iconURL
		self.tags = tags
		self.dappDefinitions = dappDefinitions
	}
}
