import ClientPrelude

// MARK: - NetworkSwitchingClient
public struct NetworkSwitchingClient: Sendable, DependencyKey {
	public var hasMainnetEverBeenLive: HasMainnetEverBeenLive
	public var validateGatewayURL: ValidateGatewayURL
	public var hasAccountOnNetwork: HasAccountOnNetwork
	public var switchTo: SwitchTo
}

extension NetworkSwitchingClient {
	public typealias HasMainnetEverBeenLive = @Sendable () async -> Bool
	public typealias ValidateGatewayURL = @Sendable (URL) async throws -> Radix.Gateway?
	public typealias HasAccountOnNetwork = @Sendable (Radix.Gateway) async throws -> Bool
	public typealias SwitchTo = @Sendable (Radix.Gateway) async throws -> Radix.Gateway
}
