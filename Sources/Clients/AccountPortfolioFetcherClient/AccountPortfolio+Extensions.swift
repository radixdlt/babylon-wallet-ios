import ClientPrelude
import EngineToolkitClient
import GatewayAPI

// MARK: - Helpers - Resources response
extension AccountPortfolio {
	init(
		owner: AccountAddress,
		response: GatewayAPI.StateEntityDetailsResponse
	) throws {
		@Dependency(\.engineToolkitClient) var engineToolkitClient

		let fungibleContainers = try response.items.compactMap(\.fungibleResources).flatMap(\.items).map { fungibleBalance in
			let balance = try BigDecimal(fromString: fungibleBalance.amount.value)
			let componentAddress = ComponentAddress(address: fungibleBalance.address)
			let networkID = try Radix.Network.lookupBy(name: response.ledgerState.network).id
			let isXRD = try engineToolkitClient.isXRD(component: componentAddress, on: networkID)
			return try FungibleTokenContainer(
				owner: .init(address: response.address),
				asset: .init(
					componentAddress: componentAddress,
					divisibility: nil,
					totalSupply: nil,
					totalMinted: nil,
					totalBurnt: nil,
					tokenDescription: nil,
					name: nil,
					symbol: nil,
					isXRD: isXRD
				),
				amount: balance,
				worth: nil
			)
		}

		let nonFungibleContainers = try response.nonFungibleResources.items.map {
			try NonFungibleTokenContainer(
				owner: .init(address: response.address),
				resourceAddress: .init(address: $0.address),
				assets: [],
				name: nil,
				description: nil,
				iconURL: nil
			)
		}

		self.owner = owner
		fungibleTokenContainers = .init(uniqueElements: fungibleContainers)
		nonFungibleTokenContainers = .init(uniqueElements: nonFungibleContainers)
		poolUnitContainers = []
		badgeContainers = []
	}
}

// MARK: - Helpers - Overview response
extension AccountPortfolio {
	mutating func updateFungibleTokens(with response: GatewayAPI.EntityOverviewResponse) {
		response.entities.forEach {
			fungibleTokenContainers[id: .init(address: $0.address)]?.update(with: $0.metadata)
		}
	}

	mutating func updateNonFungibleTokens(with response: GatewayAPI.EntityOverviewResponse) {
		response.entities.forEach {
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
		let dict: [AssetMetadata.Key: String] = .init(
			uniqueKeysWithValues: metadataCollection.items.compactMap { item in
				guard let key = AssetMetadata.Key(rawValue: item.key) else { return nil }
				return (key: key, value: item.value)
			}
		)

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
		let dict: [AssetMetadata.Key: String] = .init(
			uniqueKeysWithValues: metadataCollection.items.compactMap { item in
				guard let key = AssetMetadata.Key(rawValue: item.key) else { return nil }
				return (key: key, value: item.value)
			}
		)

		return Self(
			componentAddress: componentAddress,
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
