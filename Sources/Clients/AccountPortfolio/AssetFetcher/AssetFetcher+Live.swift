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

			let request = EntityOverviewRequest(addresses: fungibleTokenAddresses)
			let overviewResponse = try await gatewayAPIClient.resourcesOverview(request)

			accountPortfolio.update(with: overviewResponse)

			return accountPortfolio
		}
	)
}

// MARK: - Helpers - Resources response
extension AccountPortfolio {
	init(response: EntityResourcesResponse) throws {
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
					address: $0.address,
					nonFungibleID: "",
					isDeleted: false,
					nonFungibleDataAsString: ""
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
	mutating func update(with response: EntityOverviewResponse) {
		response.entities.forEach {
			fungibleTokenContainers[id: $0.address]?.update(with: $0.metadata)
		}
	}
}

extension FungibleTokenContainer {
	mutating func update(with metadataCollection: EntityMetadataCollection) {
		metadataCollection.items.forEach {
			asset.update(with: $0)
		}
	}
}

extension FungibleToken {
	mutating func update(with metadata: EntityMetadataItem) {
		switch metadata.key {
		case "symbol":
			symbol = metadata.value
		case "description":
			tokenDescription = metadata.value
		case "url":
			tokenInfoURL = metadata.value
		case "name":
			name = metadata.value
		default:
			break
		}
	}
}
