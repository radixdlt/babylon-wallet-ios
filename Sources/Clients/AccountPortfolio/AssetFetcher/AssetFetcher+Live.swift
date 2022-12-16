import Asset
import BigInt
import Common
import Dependencies
import EngineToolkit
import GatewayAPI
import Profile

// MARK: - AssetFetcher + DependencyKey
extension AssetFetcher: DependencyKey {
	public static let liveValue = Self(
		fetchAssets: { (accountAddress: AccountAddress) async throws -> AccountPortfolio in
			@Dependency(\.gatewayAPIClient) var gatewayAPIClient

			let resourcesResponse = try await gatewayAPIClient.accountResourcesByAddress(accountAddress)
			var accountPortfolio = try AccountPortfolio(response: resourcesResponse)

			let fungibleTokenAddresses = accountPortfolio.fungibleTokenContainers.map(\.asset.componentAddress)
			let nonFungibleTokenAddresses = accountPortfolio.nonFungibleTokenContainers.map(\.resourceAddress)

			if fungibleTokenAddresses.isEmpty, nonFungibleTokenAddresses.isEmpty {
				return .empty
			}

			if !fungibleTokenAddresses.isEmpty {
				let request = GatewayAPI.EntityOverviewRequest(addresses: fungibleTokenAddresses.map(\.address))
				let overviewResponse = try await gatewayAPIClient.resourcesOverview(request)
				accountPortfolio.updateFungibleTokens(with: overviewResponse)
			}

			if !nonFungibleTokenAddresses.isEmpty {
				let request = GatewayAPI.EntityOverviewRequest(addresses: nonFungibleTokenAddresses.map(\.address))
				let overviewResponse = try await gatewayAPIClient.resourcesOverview(request)
				accountPortfolio.updateNonFungibleTokens(with: overviewResponse)

				try await withThrowingTaskGroup(
					of: (ComponentAddress, [String]).self,
					returning: Void.self,
					body: { taskGroup in
						for resourceAddress in nonFungibleTokenAddresses {
							taskGroup.addTask {
								try Task.checkCancellation()
								let response = try await gatewayAPIClient.getNonFungibleIds(accountAddress, resourceAddress.address)
								let nonFungibleIds = response.nonFungibleIds.items.map(\.nonFungibleId)
								return (resourceAddress, nonFungibleIds)
							}
						}

						for try await result in taskGroup {
							accountPortfolio.updateNonFungibleTokens(
								idsResponse: result
							)
						}
					}
				)
			}

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
					componentAddress: .init(address: $0.address),
					divisibility: nil,
					totalSupplyAttos: nil,
					totalMintedAttos: nil,
					totalBurntAttos: nil,
					tokenDescription: nil,
					name: nil,
					symbol: nil
				),
				amount: $0.amount.value,
				worth: nil
			)
		}

		let nonFungibleContainers = try response.nonFungibleResources.items.map {
			NonFungibleTokenContainer(
				owner: try .init(address: response.address),
				resourceAddress: .init(address: $0.address),
				assets: [],
				name: nil,
				symbol: nil
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
			symbol: dict[.symbol]
		)
	}

	mutating func updateWithAssetIds(ids: [String]) -> Self {
		Self(
			owner: owner,
			resourceAddress: resourceAddress,
			assets: ids.map { NonFungibleToken(nonFungibleId: .string($0)) },
			name: name,
			symbol: symbol
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
