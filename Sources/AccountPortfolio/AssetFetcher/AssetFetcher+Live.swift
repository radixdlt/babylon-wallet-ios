import Address
import Asset
import ComposableArchitecture
import GatewayAPI

public extension AssetFetcher {
	static let live: Self = {
		@Dependency(\.gatewayAPIClient) var apiClient

		return Self(
			fetchAssets: { address in

				let resources = try await apiClient.accountResourcesByAddress(address)

				let entityDetails = try await withThrowingTaskGroup(
					of: EntityDetailsResponseDetails.self,
					returning: [EntityDetailsResponseDetails].self,
					body: { taskGroup in
						for result in resources.fungibleResources.results {
							taskGroup.addTask {
								let details = try await apiClient.resourceDetailsByResourceIdentifier(result.address)
								return details
							}
						}

						for result in resources.nonFungibleResources.results {
							taskGroup.addTask {
								let details = try await apiClient.resourceDetailsByResourceIdentifier(result.address)
								return details
							}
						}

						var entityDetails = [EntityDetailsResponseDetails]()
						for try await result in taskGroup {
							entityDetails.append(result)
						}

						return entityDetails
					}
				)

				// TODO: replace with real implementation when API is ready
				return AssetGenerator.mockAssets
			}
		)
	}()
}
