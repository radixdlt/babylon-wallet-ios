import Foundation
import Prelude
import ProfileClient

// MARK: - NetworkSwitchingClient
public struct NetworkSwitchingClient: Sendable, DependencyKey {
	public var getNetworkAndGateway: GetNetworkAndGateway
	public var validateGatewayURL: ValidateGatewayURL
	public var hasAccountOnNetwork: HasAccountOnNetwork
	public var switchTo: SwitchTo
}

public extension NetworkSwitchingClient {
	typealias GetNetworkAndGateway = @Sendable () async -> AppPreferences.NetworkAndGateway
	typealias ValidateGatewayURL = @Sendable (URL) async throws -> AppPreferences.NetworkAndGateway?
	typealias HasAccountOnNetwork = @Sendable (AppPreferences.NetworkAndGateway) async throws -> Bool
	typealias SwitchTo = @Sendable (AppPreferences.NetworkAndGateway) async throws -> AppPreferences.NetworkAndGateway
}
