import FeaturePrelude

// MARK: - NetworkSwitchingClient
public struct NetworkSwitchingClient: Sendable, DependencyKey {
	public var getGateway: GetGateway
	public var validateGatewayURL: ValidateGatewayURL
	public var hasAccountOnNetwork: HasAccountOnNetwork
	public var switchTo: SwitchTo
}

extension NetworkSwitchingClient {
	public typealias GetGateway = @Sendable () async -> Gateway
	public typealias ValidateGatewayURL = @Sendable (URL) async throws -> Gateway?
	public typealias HasAccountOnNetwork = @Sendable (Gateway) async throws -> Bool
	public typealias SwitchTo = @Sendable (Gateway) async throws -> Gateway
}
