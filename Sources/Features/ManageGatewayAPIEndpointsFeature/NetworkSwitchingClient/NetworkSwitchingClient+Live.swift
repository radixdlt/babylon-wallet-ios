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

		let getGateway: GetGateway = {
			await profileClient.getGateways().current
		}

		let validateGatewayURL: ValidateGatewayURL = { newURL -> Gateway? in
			let currentURL = await getGateway().url
			guard newURL != currentURL else {
				return nil
			}
			let name = try await gatewayAPIClient.getNetworkName(newURL)
			// FIXME: mainnet: also compare `NetworkID` from lookup with NetworkID from `getNetworkInformation` call
			// once it returns networkID!
			let network = try Network.lookupBy(name: name)

			let gateway = Gateway(
				network: network,
				url: newURL
			)

			return gateway
		}

		let hasAccountOnNetwork: HasAccountOnNetwork = { gateway in
			try await profileClient.hasAccountOnNetwork(gateway.network.id)
		}

		let switchTo: SwitchTo = { gateway in
			guard try await hasAccountOnNetwork(gateway) else {
				throw NoAccountOnNetwork()
			}

			try await profileClient.setGateway(gateway)
			return gateway
		}

		return Self(
			getGateway: getGateway,
			validateGatewayURL: validateGatewayURL,
			hasAccountOnNetwork: hasAccountOnNetwork,
			switchTo: switchTo
		)
	}()
}

// MARK: - NoAccountOnNetwork
struct NoAccountOnNetwork: Swift.Error {}
