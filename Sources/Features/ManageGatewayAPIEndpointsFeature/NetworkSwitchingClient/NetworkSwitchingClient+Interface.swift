import FeaturePrelude

// MARK: - NetworkSwitchingClient
public struct NetworkSwitchingClient: Sendable, DependencyKey {
	public var getNetworkAndGateway: GetNetworkAndGateway
	public var validateGatewayURL: ValidateGatewayURL
	public var hasAccountOnNetwork: HasAccountOnNetwork
	public var switchTo: SwitchTo
}

extension NetworkSwitchingClient {
	public typealias GetNetworkAndGateway = @Sendable () async -> AppPreferences.NetworkAndGateway
	public typealias ValidateGatewayURL = @Sendable (URL) async throws -> AppPreferences.NetworkAndGateway?
	public typealias HasAccountOnNetwork = @Sendable (AppPreferences.NetworkAndGateway) async throws -> Bool
	public typealias SwitchTo = @Sendable (AppPreferences.NetworkAndGateway) async throws -> AppPreferences.NetworkAndGateway
}
