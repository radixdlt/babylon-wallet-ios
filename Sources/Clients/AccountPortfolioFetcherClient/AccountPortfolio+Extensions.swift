import ClientPrelude
import EngineToolkitClient
import GatewayAPI

// MARK: - Helpers - Resources response
extension AccountPortfolio {
	init(
		owner: AccountAddress,
		response: GatewayAPIClient.AccountDetailsResponse
	) throws {
		@Dependency(\.engineToolkitClient) var engineToolkitClient

		let networkID = try Radix.Network.lookupBy(name: response.ledgerState.network).id

		let fungibleContainers: [FungibleTokenContainer] = try response
			.details
			.fungibleResources?
			.items
			.compactMap(\.global)
			.map { item in
				let balance = try BigDecimal(fromString: item.amount)
				let resourceAddress = ResourceAddress(address: item.resourceAddress)
				let isXRD = try engineToolkitClient.isXRD(resource: resourceAddress, on: networkID)

				return try FungibleTokenContainer(owner: .init(address: response.details.address),
				                                  asset: .init(
				                                  	resourceAddress: resourceAddress,
				                                  	isXRD: isXRD
				                                  ),
				                                  amount: balance,
				                                  worth: nil)
			} ?? []

		let nonFungibleContainers: [NonFungibleTokenContainer] = try response
			.details
			.nonFungibleResources?
			.items
			.compactMap(\.global)
			.map { item in
				try NonFungibleTokenContainer(
					owner: .init(address: response.details.address),
					resourceAddress: .init(address: item.resourceAddress),
					assets: [],
					name: nil,
					description: nil,
					iconURL: nil
				)
			} ?? []

		self.owner = owner
		fungibleTokenContainers = .init(uniqueElements: fungibleContainers)
		nonFungibleTokenContainers = .init(uniqueElements: nonFungibleContainers)
		poolUnitContainers = []
		badgeContainers = []
	}
}

// MARK: - Helpers - Overview response
extension AccountPortfolio {
	mutating func updateFungibleTokens(with response: GatewayAPI.StateEntityDetailsResponse) {
		response.items.forEach {
			fungibleTokenContainers[id: .init(address: $0.address)]?.update(with: $0.metadata)
		}
	}

	mutating func updateNonFungibleTokens(with response: GatewayAPI.StateEntityDetailsResponse) {
		response.items.forEach {
			nonFungibleTokenContainers[id: .init(address: $0.address)] = nonFungibleTokenContainers[id: .init(address: $0.address)]?.update(with: $0.metadata)
		}
	}

	mutating func updateNonFungibleTokens(idsResponse: (address: ComponentAddress, nftIds: [String])) {
		nonFungibleTokenContainers[id: idsResponse.address] = nonFungibleTokenContainers[id: idsResponse.address]?.updateWithAssetIds(ids: idsResponse.nftIds)
	}
}

extension FungibleTokenContainer {
	mutating func update(with metadataCollection: GatewayAPI.EntityMetadataCollection) {
		asset = asset.updated(with: metadataCollection)
	}
}

extension NonFungibleTokenContainer {
	mutating func update(with metadataCollection: GatewayAPI.EntityMetadataCollection) -> Self {
		let dict = metadataCollection.asDictionary

		return Self(
			owner: owner,
			resourceAddress: resourceAddress,
			assets: assets,
			name: dict[.name],
			description: dict[.description],
			iconURL: dict[.icon].flatMap(URL.init(string:))
		)
	}

	mutating func updateWithAssetIds(ids: [String]) -> Self {
		Self(
			owner: owner,
			resourceAddress: resourceAddress,
			assets: ids.map { NonFungibleToken(nonFungibleLocalId: .string($0)) },
			name: name,
			description: description,
			iconURL: iconURL
		)
	}
}

extension FungibleToken {
	func updated(with metadataCollection: GatewayAPI.EntityMetadataCollection) -> Self {
		let dict = metadataCollection.asDictionary

		return Self(
			resourceAddress: resourceAddress,
			divisibility: divisibility,
			totalSupply: totalSupply,
			totalMinted: totalMinted,
			totalBurnt: totalBurnt,
			tokenDescription: dict[.description],
			name: dict[.name],
			symbol: dict[.symbol],
			isXRD: isXRD,
			tokenInfoURL: dict[.url]
		)
	}
}

extension GatewayAPI.EntityMetadataCollection {
	var asDictionary: [AssetMetadata.Key: String] {
		.init(
			uniqueKeysWithValues: items.compactMap { item in
				guard let key = AssetMetadata.Key(rawValue: item.key),
				      let value = item.value.asString else { return nil }
				return (key: key, value: value)
			}
		)
	}
}
