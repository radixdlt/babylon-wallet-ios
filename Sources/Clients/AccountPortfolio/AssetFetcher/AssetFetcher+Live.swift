import Asset
import BigInt
import Common
import Dependencies
import GatewayAPI
import Profile

/*
 public extension V0StateComponentResponse {
 	func asSimpleOwnedAssets(owner: AccountAddress) throws -> SimpleOwnedAssets {
 		let simpleOwnedFungibleTokens = try ownedVaults.compactMap(\.fungibleResourceAmount)
 			.map {
 				SimpleOwnedFungibleToken(
 					owner: owner,
 					amountInAttos: try BigUInt(decimalString: $0.amountAttos),
 					tokenResourceAddress: $0.resourceAddress
 				)
 			}

 		let simpleOwnedNonFungibleTokens = ownedVaults.compactMap { $0.vault?.resourceAmount.nonFungibleResourceAmount }
 			.map {
 				SimpleOwnedNonFungibleToken(
 					owner: owner,
 					nonFungibleIDS: $0.nfIdsHex,
 					tokenResourceAddress: $0.resourceAddress
 				)
 			}

 		return SimpleOwnedAssets(
 			simpleOwnedFungibleTokens: simpleOwnedFungibleTokens,
 			simpleOwnedNonFungibleTokens: simpleOwnedNonFungibleTokens
 		)
 	}
 }
 */

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

		fungibleTokenContainers = fungibleContainers
		nonFungibleTokenContainers = nonFungibleContainers
		poolShareContainers = []
		badgeContainers = []
	}
}

extension FungibleToken {
	mutating func populate(with metadata: EntityMetadataItem) {
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

// MARK: - AssetFetcher + DependencyKey
extension AssetFetcher: DependencyKey {
	public static let liveValue = Self(
		fetchAssets: { (accountAddress: AccountAddress) async throws -> AccountPortfolio in
			@Dependency(\.gatewayAPIClient) var gatewayAPIClient

			let resourcesResponse = try await gatewayAPIClient.accountResourcesByAddress(accountAddress)
			let accountPortfolio = try AccountPortfolio(response: resourcesResponse)

			let fungibleTokenAddresses = accountPortfolio.fungibleTokenContainers.map(\.asset.address)
//			let nonFungibleTokenAddresses = accountPortfolio.nonFungibleTokenContainers.map { $0.asset.address }

			let request = EntityOverviewRequest(addresses: fungibleTokenAddresses)
			let temp = try await gatewayAPIClient.resourcesOverview(request)

			temp.entities

			return accountPortfolio

			/*
			 let fungibleTokenContainers = resourcesResponse.fungibleResources.items.map { FungibleTokenContainer(responseItem: $0) }

			 let fungibleToken

			 let simpleOwnedAssets: SimpleOwnedAssets = try resourcesResponse.asSimpleOwnedAssets(owner: accountAddress)

			 let detailsOfResources: [ResourceDetails] = try await withThrowingTaskGroup(
			 	of: ResourceDetails.self,
			 	returning: [ResourceDetails].self,
			 	body: { taskGroup in
			 		for simpleOwnedFungibleToken in simpleOwnedAssets.simpleOwnedFungibleTokens {
			 			taskGroup.addTask {
			 				let details = try await gatewayAPIClient.resourceDetailsByResourceIdentifier(simpleOwnedFungibleToken.tokenResourceAddress)
			 				return .init(
			 					simpleOwnedAsset: .simpleOwnedFungibleToken(simpleOwnedFungibleToken),
			 					details: details
			 				)
			 			}
			 		}

			 		for simpleOwnedNonFungibleToken in simpleOwnedAssets.simpleOwnedNonFungibleTokens {
			 			taskGroup.addTask {
			 				let details = try await gatewayAPIClient.resourceDetailsByResourceIdentifier(simpleOwnedNonFungibleToken.tokenResourceAddress)
			 				return .init(
			 					simpleOwnedAsset: .simpleOwnedNonFungibleToken(simpleOwnedNonFungibleToken),
			 					details: details
			 				)
			 			}
			 		}

			 		var resourceDetails = [ResourceDetails]()
			 		for try await result in taskGroup {
			 			resourceDetails.append(result)
			 		}

			 		return resourceDetails
			 	}
			 )

			 let ownedFungibleTokens: [OwnedFungibleToken] = try detailsOfResources.filter { $0.simpleOwnedAsset.simpleOwnedFungibleToken != nil }.map {
			 	guard let simpleOwnedFungibleToken = $0.simpleOwnedAsset.simpleOwnedFungibleToken else {
			 		fatalError("We just filtered on `simpleOwnedFungibleToken`, so this should not happend")
			 	}
			 	guard let resourceManagerSubstate = $0.details.manager.resourceManagerSubstate else {
			 		fatalError("Expected fungible token to always have a `resourceManagerSubstate`")
			 	}
			 	let fungibleToken = try FungibleToken(
			 		address: simpleOwnedFungibleToken.tokenResourceAddress,
			 		resourceManagerSubstate: resourceManagerSubstate
			 	)
			 	return OwnedFungibleToken(
			 		owner: simpleOwnedFungibleToken.owner,
			 		amountInAttos: simpleOwnedFungibleToken.amountInAttos,
			 		token: fungibleToken
			 	)
			 }

			 let ownedNonFungibleTokens: [OwnedNonFungibleToken] = detailsOfResources.filter { $0.simpleOwnedAsset.simpleOwnedNonFungibleToken != nil }.map {
			 	guard let simpleOwnedNonFungibleToken = $0.simpleOwnedAsset.simpleOwnedNonFungibleToken else {
			 		fatalError("We just filtered on `simpleOwnedNonFungibleToken`, so this should not happend")
			 	}
			 	guard let nonFungibleSubstate = $0.details.manager.nonFungibleSubstate else {
			 		fatalError("Expected fungible token to always have a `nonFungibleSubstate`")
			 	}
			 	let nonFungibleToken = NonFungibleToken(
			 		address: simpleOwnedNonFungibleToken.tokenResourceAddress,
			 		nonFungibleSubstate: nonFungibleSubstate
			 	)

			 	return OwnedNonFungibleToken(
			 		owner: simpleOwnedNonFungibleToken.owner,
			 		nonFungibleIDS: simpleOwnedNonFungibleToken.nonFungibleIDS,
			 		token: nonFungibleToken
			 	)
			 }

			 return OwnedAssets(
			 	ownedFungibleTokens: ownedFungibleTokens,
			 	ownedNonFungibleTokens: ownedNonFungibleTokens
			 )
			 */
		}
	)
}

/*
 // MARK: - AssetFetcher.ResourceDetails
 private extension AssetFetcher {
 	struct ResourceDetails {
 		let simpleOwnedAsset: SimpleOwnedAsset
 		let details: V0StateResourceResponse
 	}
 }
 */
