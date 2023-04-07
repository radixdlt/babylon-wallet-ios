import AccountsClient
import CacheClient
import ClientPrelude
import GatewayAPI
import GatewaysClient
import ProfileStore

extension DependencyValues {
	public var networkSwitchingClient: NetworkSwitchingClient {
		get { self[NetworkSwitchingClient.self] }
		set { self[NetworkSwitchingClient.self] = newValue }
	}
}

extension NetworkSwitchingClient {
	public static let liveValue = Self.live()

	public static func live(
		profileStore getProfileStore: @escaping @Sendable () async -> ProfileStore = { await .shared }
	) -> Self {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.gatewaysClient) var gatewaysClient
		@Dependency(\.accountsClient) var accountsClient
		@Dependency(\.cacheClient) var cacheClient

		let getCurrentGateway: GetCurrentGateway = {
			await gatewaysClient.getCurrentGateway()
		}

		let validateGatewayURL: ValidateGatewayURL = { newURL -> Radix.Gateway? in
			let currentURL = await gatewaysClient.getGatewayAPIEndpointBaseURL()
			guard newURL != currentURL else {
				return nil
			}

			let name = try await cacheClient.withCaching(
				cacheEntry: .networkName(newURL.absoluteString),
				request: {
					try await gatewayAPIClient.getNetworkName(newURL)
				}
			)

			// FIXME: mainnet: also compare `NetworkID` from lookup with NetworkID from `getNetworkInformation` call
			// once it returns networkID!
			let network = try Radix.Network.lookupBy(name: name)

			let gateway = Radix.Gateway(
				network: network,
				url: newURL
			)

			return gateway
		}

		let hasAccountOnNetwork: HasAccountOnNetwork = { gateway in
			try await accountsClient.hasAccountOnNetwork(gateway.network.id)
		}

		let switchTo: SwitchTo = { gateway in
			guard try await hasAccountOnNetwork(gateway) else {
				throw NoAccountOnNetwork()
			}

			try await gatewaysClient.changeGateway(gateway)
			return gateway
		}

		return Self(
			getCurrentGateway: getCurrentGateway,
			validateGatewayURL: validateGatewayURL,
			hasAccountOnNetwork: hasAccountOnNetwork,
			switchTo: switchTo
		)
	}
}

// MARK: - NoAccountOnNetwork
struct NoAccountOnNetwork: Swift.Error {}
