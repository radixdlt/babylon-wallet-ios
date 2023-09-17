import Foundation

extension AccountPortfolio.NonFungibleResource {
	public init(resourceAddress: ResourceAddress, metadata: [String: MetadataValue?]) {
		self.init(
			resourceAddress: resourceAddress,
			name: metadata.name,
			description: metadata.description,
			iconURL: metadata.iconURL,
			tags: metadata.tags
		)
	}

	public init(onLedgerEntity: OnLedgerEntity.Resource, tokens: IdentifiedArrayOf<NonFungibleToken> = []) {
		self.init(
			resourceAddress: onLedgerEntity.resourceAddress,
			name: onLedgerEntity.name,
			description: onLedgerEntity.description,
			iconURL: onLedgerEntity.iconURL,
			behaviors: onLedgerEntity.behaviors,
			tags: onLedgerEntity.tags,
			tokens: tokens,
			totalSupply: onLedgerEntity.totalSupply
		)
	}
}

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
			metadata: [], // FIXME: Find?
			stakeClaimAmount: nil,
			canBeClaimed: false // FIXME: Find?
		)
	}
}

extension AccountPortfolio.FungibleResource {
	public init(resourceAddress: ResourceAddress, amount: BigDecimal, metadata: [String: MetadataValue?]) {
		self.init(
			resourceAddress: resourceAddress,
			amount: amount,
			name: metadata.name,
			symbol: metadata.symbol,
			description: metadata.description,
			iconURL: metadata.iconURL,
			tags: metadata.tags
		)
	}

	public init(amount: BigDecimal, onLedgerEntity: OnLedgerEntity.Resource) {
		self.init(
			resourceAddress: onLedgerEntity.resourceAddress,
			amount: amount,
			divisibility: onLedgerEntity.divisibility,
			name: onLedgerEntity.name,
			symbol: onLedgerEntity.symbol,
			description: onLedgerEntity.description,
			iconURL: onLedgerEntity.iconURL,
			behaviors: onLedgerEntity.behaviors,
			tags: onLedgerEntity.tags,
			totalSupply: onLedgerEntity.totalSupply
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
