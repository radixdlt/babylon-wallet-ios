import ClientPrelude

// MARK: - NetworkSwitchingClient
public struct NetworkSwitchingClient: Sendable, DependencyKey {
	public var getCurrentGateway: GetCurrentGateway
	public var validateGatewayURL: ValidateGatewayURL
	public var hasAccountOnNetwork: HasAccountOnNetwork
	public var switchTo: SwitchTo
}

extension NetworkSwitchingClient {
	public typealias GetCurrentGateway = @Sendable () async -> Radix.Gateway
	public typealias ValidateGatewayURL = @Sendable (URL) async throws -> Radix.Gateway?
	public typealias HasAccountOnNetwork = @Sendable (Radix.Gateway) async throws -> Bool
	public typealias SwitchTo = @Sendable (Radix.Gateway) async throws -> Radix.Gateway
}
