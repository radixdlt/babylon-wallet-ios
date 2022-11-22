import Asset
import BigInt
import Common
import Dependencies
import GatewayAPI
import Profile

// MARK: - AssetFetcher + DependencyKey
extension AssetFetcher: DependencyKey {
	public static let liveValue = Self(
		fetchAssets: { (accountAddress: AccountAddress) async throws -> AccountPortfolio in
			@Dependency(\.gatewayAPIClient) var gatewayAPIClient

			let resourcesResponse = try await gatewayAPIClient.accountResourcesByAddress(accountAddress)
			var accountPortfolio = try AccountPortfolio(response: resourcesResponse)

			let fungibleTokenAddresses = accountPortfolio.fungibleTokenContainers.map(\.asset.address)
			let nonFungibleTokenAddresses = accountPortfolio.nonFungibleTokenContainers.map(\.asset.address)

			let request = GatewayAPI.EntityOverviewRequest(addresses: fungibleTokenAddresses)
			let overviewResponse = try await gatewayAPIClient.resourcesOverview(request)

			accountPortfolio.update(with: overviewResponse)

			return accountPortfolio
		}
	)
}

// MARK: - Helpers - Resources response
extension AccountPortfolio {
	init(response: GatewayAPI.EntityResourcesResponse) throws {
		let fungibleContainers = try response.fungibleResources.items.map {
			FungibleTokenContainer(
				owner: try .init(address: response.address),
				asset: .init(
					address: $0.address,
					divisibility: nil,
					totalSupplyAttos: nil,
					totalMintedAttos: nil,
					totalBurntAttos: nil,
					tokenDescription: nil,
					name: nil,
					symbol: nil
				),
				amountInAttos: BigUInt(stringLiteral: $0.amount.value),
				worth: nil
			)
		}

		let nonFungibleContainers = try response.nonFungibleResources.items.map {
			NonFungibleTokenContainer(
				owner: try .init(address: response.address),
				asset: .init(
					address: $0.address
				),
				metadata: nil
			)
		}

		fungibleTokenContainers = .init(uniqueElements: fungibleContainers)
		nonFungibleTokenContainers = .init(uniqueElements: nonFungibleContainers)
		poolShareContainers = []
		badgeContainers = []
	}
}

// MARK: - Helpers - Overview response
extension AccountPortfolio {
	mutating func update(with response: GatewayAPI.EntityOverviewResponse) {
		response.entities.forEach {
			fungibleTokenContainers[id: $0.address]?.update(with: $0.metadata)
		}
	}
}

extension FungibleTokenContainer {
	mutating func update(with metadataCollection: GatewayAPI.EntityMetadataCollection) {
		asset = asset.updated(with: metadataCollection)
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
			address: address,
			divisibility: divisibility,
			totalSupplyAttos: totalSupplyAttos,
			totalMintedAttos: totalMintedAttos,
			totalBurntAttos: totalBurntAttos,
			tokenDescription: dict[.description],
			name: dict[.name],
			symbol: dict[.symbol],
			tokenInfoURL: dict[.url]
		)
	}
}
