import ClientPrelude
import GatewayAPI

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
								let response = try await gatewayAPIClient.getNonFungibleLocalIds(accountAddress, resourceAddress.address)
								let nonFungibleLocalIds = response.nonFungibleLocalIds.items.map(\.nonFungibleLocalId)
								return (resourceAddress, nonFungibleLocalIds)
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
					totalSupply: nil,
					totalMinted: nil,
					totalBurnt: nil,
					tokenDescription: nil,
					name: nil,
					symbol: nil,
					isXRD: false // Can these be XRD?
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
				description: nil,
				iconURL: nil
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
