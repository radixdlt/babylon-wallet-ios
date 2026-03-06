// MARK: - NetworkSwitchingClient
struct NetworkSwitchingClient: DependencyKey {
	var validateGatewayURL: ValidateGatewayURL
	var hasAccountOnNetwork: HasAccountOnNetwork
	var switchTo: SwitchTo
}

extension NetworkSwitchingClient {
	typealias ValidateGatewayURL = @Sendable (URL) async throws -> Gateway?
	typealias HasAccountOnNetwork = @Sendable (Gateway) async throws -> Bool
	typealias SwitchTo = @Sendable (Gateway) async throws -> Gateway
}
