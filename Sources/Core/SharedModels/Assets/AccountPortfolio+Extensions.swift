import Foundation

extension AccountPortfolio.NonFungibleResource.NonFungibleToken {
	public init(resourceAddress: ResourceAddress, nftID: NonFungibleLocalId, nftData: [NFTData]) throws {
		try self.init(
			id: .fromParts(
				resourceAddress: resourceAddress.intoEngine(),
				nonFungibleLocalId: nftID
			),
			name: nftData.name,
			description: nftData.description,
			keyImageURL: nftData.keyImageURL,
			stakeClaimAmount: nil
		)
	}
}

extension OnLedgerEntity.Resource {
	public init(resourceAddress: ResourceAddress, metadata: [String: MetadataValue?]) {
		self.init(
			resourceAddress: resourceAddress,
			divisibility: nil,
			name: metadata.name,
			symbol: metadata.symbol,
			description: metadata.description,
			iconURL: metadata.iconURL,
			behaviors: [],
			tags: metadata.tags,
			totalSupply: nil
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
