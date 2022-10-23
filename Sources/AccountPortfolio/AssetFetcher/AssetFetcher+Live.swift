import Asset
import ComposableArchitecture
import GatewayAPI
import Profile

public extension AssetFetcher {
	static func live(
		gatewayAPIClient: GatewayAPIClient = .live()
	) -> Self {
		Self(
			fetchAssets: { (address: AccountAddress) async throws -> [[any Asset]] in
				let resources = try await gatewayAPIClient.accountResourcesByAddress(address)

				let resourceDetails = try await withThrowingTaskGroup(
					of: ResourceDetails.self,
					returning: [ResourceDetails].self,
					body: { taskGroup in
						for resource in resources.ownedVaults.compactMap(\.fungibleResourceAmount) {
							taskGroup.addTask {
								let details = try await gatewayAPIClient.resourceDetailsByResourceIdentifier(resource.resourceAddress)
								return .init(address: resource.resourceAddress, details: details)
							}
						}

						for resource in resources.ownedVaults.compactMap({ $0.vault?.resourceAmount.nonFungibleResourceAmount }) {
							taskGroup.addTask {
								let details = try await gatewayAPIClient.resourceDetailsByResourceIdentifier(resource.resourceAddress)
								return .init(address: resource.resourceAddress, details: details)
							}
						}

						var resourceDetails = [ResourceDetails]()
						for try await result in taskGroup {
							resourceDetails.append(result)
						}

						return resourceDetails
					}
				)

				var fungibleTokens = [any Asset]()
				var nonFungibleTokens = [any Asset]()

				for detailedResource in resourceDetails {
					switch detailedResource.details.manager {
					case let .typeResourceManagerSubstate(fungible):
						try fungibleTokens.append(
							FungibleToken(
								address: detailedResource.address,
								resourceManagerSubstate: fungible
							)
						)
					case let .typeNonFungibleSubstate(nonFungible):
						nonFungibleTokens.append(
							NonFungibleToken(
								address: detailedResource.address,
								nonFungibleSubstate: nonFungible
							)
						)
					default: continue
					}
				}

				return [fungibleTokens, nonFungibleTokens]
			}
		)
	}
}

// MARK: - AssetFetcher.ResourceDetails
private extension AssetFetcher {
	struct ResourceDetails {
		let address: String
		let details: V0StateResourceResponse
	}
}
