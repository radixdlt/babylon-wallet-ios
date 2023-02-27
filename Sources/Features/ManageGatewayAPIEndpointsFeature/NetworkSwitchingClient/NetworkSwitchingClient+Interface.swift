import FeaturePrelude

// MARK: - NetworkSwitchingClient
public struct NetworkSwitchingClient: Sendable, DependencyKey {
	public var getNetworkAndGateway: GetNetworkAndGateway
	public var validateGatewayURL: ValidateGatewayURL
	public var hasAccountOnNetwork: HasAccountOnNetwork
	public var switchTo: SwitchTo
}

extension NetworkSwitchingClient {
	public typealias GetNetworkAndGateway = @Sendable () async -> NetworkAndGateway
	public typealias ValidateGatewayURL = @Sendable (URL) async throws -> NetworkAndGateway?
	public typealias HasAccountOnNetwork = @Sendable (NetworkAndGateway) async throws -> Bool
	public typealias SwitchTo = @Sendable (NetworkAndGateway) async throws -> NetworkAndGateway
}
