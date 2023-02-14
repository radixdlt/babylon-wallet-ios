import FeaturePrelude
import GatewayAPI
import ProfileClient

extension DependencyValues {
	public var networkSwitchingClient: NetworkSwitchingClient {
		get { self[NetworkSwitchingClient.self] }
		set { self[NetworkSwitchingClient.self] = newValue }
	}
}

extension NetworkSwitchingClient {
	public static let liveValue: Self = {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.profileClient) var profileClient

		let getNetworkAndGateway: GetNetworkAndGateway = {
			await profileClient.getNetworkAndGateway()
		}

		let validateGatewayURL: ValidateGatewayURL = { newURL -> AppPreferences.NetworkAndGateway? in
			let currentURL = await getNetworkAndGateway().gatewayAPIEndpointURL
			guard newURL != currentURL else {
				return nil
			}
			let name = try await gatewayAPIClient.getNetworkName(newURL)
			// FIXME: mainnet: also compare `NetworkID` from lookup with NetworkID from `getNetworkInformation` call
			// once it returns networkID!
			let network = try Network.lookupBy(name: name)

			let networkAndGateway = AppPreferences.NetworkAndGateway(
				network: network,
				gatewayAPIEndpointURL: newURL
			)

			return networkAndGateway
		}

		let hasAccountOnNetwork: HasAccountOnNetwork = { networkAndGateway in
			try await profileClient.hasAccountOnNetwork(networkAndGateway.network.id)
		}

		let switchTo: SwitchTo = { networkAndGateway in
			guard try await hasAccountOnNetwork(networkAndGateway) else {
				throw NoAccountOnNetwork()
			}

			try await profileClient.setNetworkAndGateway(networkAndGateway)
			return networkAndGateway
		}

		return Self(
			getNetworkAndGateway: getNetworkAndGateway,
			validateGatewayURL: validateGatewayURL,
			hasAccountOnNetwork: hasAccountOnNetwork,
			switchTo: switchTo
		)
	}()
}

// MARK: - NoAccountOnNetwork
struct NoAccountOnNetwork: Swift.Error {}
