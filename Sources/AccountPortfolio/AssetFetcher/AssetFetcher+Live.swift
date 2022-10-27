import Asset
import BigInt
import Common
import ComposableArchitecture
import GatewayAPI
import Profile

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

// MARK: - AssetFetcher + DependencyKey
extension AssetFetcher: DependencyKey {
	public static let liveValue = Self(
		fetchAssets: { (accountAddress: AccountAddress) async throws -> OwnedAssets in
			@Dependency(\.gatewayAPIClient) var gatewayAPIClient

			let resourcesRaw = try await gatewayAPIClient.accountResourcesByAddress(accountAddress)

			let simpleOwnedAssets: SimpleOwnedAssets = try resourcesRaw.asSimpleOwnedAssets(owner: accountAddress)

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
		}
	)
}

// MARK: - AssetFetcher.ResourceDetails
private extension AssetFetcher {
	struct ResourceDetails {
		let simpleOwnedAsset: SimpleOwnedAsset
		let details: V0StateResourceResponse
	}
}
