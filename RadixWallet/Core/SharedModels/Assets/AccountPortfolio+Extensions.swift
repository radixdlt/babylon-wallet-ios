
extension OnLedgerEntity.NonFungibleToken {
	public init(resourceAddress: ResourceAddress, nftID: NonFungibleLocalId, nftData: NFTData?) throws {
		try self.init(
			id: .fromParts(
				resourceAddress: resourceAddress,
				nonFungibleLocalId: nftID
			),
			data: nftData
		)
	}
}

extension OnLedgerEntity.Resource {
	public init(resourceAddress: ResourceAddress, metadata: OnLedgerEntity.Metadata) {
		self.init(
			resourceAddress: resourceAddress,
			atLedgerState: .init(version: 0, epoch: 0),
			divisibility: nil,
			behaviors: [],
			totalSupply: nil,
			metadata: metadata
		)
	}
}

extension [String: MetadataValue?] {
	var name: String? {
		self["name"]??.string
	}

	var symbol: String? {
		self["symbol"]??.string
	}

	var iconURL: URL? {
		self["icon_url"]??.url
	}

	var description: String? {
		self["description"]??.string
	}

	var tags: [AssetTag] {
		self["tags"]??.stringArray?.compactMap { NonEmptyString(rawValue: $0) }.map(AssetTag.custom) ?? []
	}
}
