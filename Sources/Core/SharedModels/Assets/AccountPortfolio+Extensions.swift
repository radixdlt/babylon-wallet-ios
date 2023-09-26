import Foundation

extension OnLedgerEntity.NonFungibleToken {
	public init(resourceAddress: ResourceAddress, nftID: NonFungibleLocalId, nftData: [NFTData]) throws {
		try self.init(
			id: .fromParts(
				resourceAddress: resourceAddress.intoEngine(),
				nonFungibleLocalId: nftID
			),
			name: nftData.name,
			description: nftData.description,
			keyImageURL: nftData.keyImageURL,
			metadata: [], // FIXME: Find?
			stakeClaimAmount: nil,
			canBeClaimed: false // FIXME: Find?
		)
	}
}

extension OnLedgerEntity.Resource {
	public init(resourceAddress: ResourceAddress, metadata: [String: MetadataValue?]) {
		self.init(
			resourceAddress: resourceAddress,
			divisibility: nil,
			behaviors: [],
			totalSupply: nil,
			resourceMetadata: .init(
				name: metadata.name,
				symbol: metadata.symbol,
				description: metadata.description,
				iconURL: metadata.iconURL,
				tags: metadata.tags
			)
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
