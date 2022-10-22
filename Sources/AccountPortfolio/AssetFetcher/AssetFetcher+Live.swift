import Asset
import ComposableArchitecture
import GatewayAPI
import Profile

public extension AssetFetcher {
	static let live: Self = {
		@Dependency(\.gatewayAPIClient) var apiClient

		return Self(
			fetchAssets: { _ in
//				let resources = try await apiClient.accountResourcesByAddress(address)
//
//				let resourceDetails = try await withThrowingTaskGroup(
//					of: ResourceDetails.self,
//					returning: [ResourceDetails].self,
//					body: { taskGroup in
//						for resource in resources.fungibleResources.results {
//							taskGroup.addTask {
//								let details = try await apiClient.resourceDetailsByResourceIdentifier(resource.address)
//								return .init(address: resource.address, details: details)
//							}
//						}
//
//						for resource in resources.nonFungibleResources.results {
//							taskGroup.addTask {
//								let details = try await apiClient.resourceDetailsByResourceIdentifier(resource.address)
//								return .init(address: resource.address, details: details)
//							}
//						}
//
//						var resourceDetails = [ResourceDetails]()
//						for try await result in taskGroup {
//							resourceDetails.append(result)
//						}
//
//						return resourceDetails
//					}
//				)
//
//				var fungibleTokens = [any Asset]()
//				var nonFungibleTokens = [any Asset]()
//
//				try resourceDetails.forEach {
//					switch $0.details {
//					case let .typeEntityDetailsResponseFungibleDetails(details):
//						try fungibleTokens.append(FungibleToken(address: $0.address, details: details))
//					case let .typeEntityDetailsResponseNonFungibleDetails(details):
//						nonFungibleTokens.append(NonFungibleToken(address: $0.address, details: details))
//					}
//				}
//
//				return [fungibleTokens, nonFungibleTokens]
				[]
			}
		)
	}()
}

// MARK: - AssetFetcher.ResourceDetails
private extension AssetFetcher {
	struct ResourceDetails {
		let address: String
		let details: V0StateResourceResponse
	}
}
