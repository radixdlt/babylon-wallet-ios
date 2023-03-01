import ClientPrelude
import Profile

// MARK: - GatewaysClient
public struct GatewaysClient: Sendable {
	public var getCurrentNetworkID: GetCurrentNetworkID
	public var getGatewayAPIEndpointBaseURL: GetGatewayAPIEndpointBaseURL
	public var getGateways: GetGateways
	public var addGateway: AddGateway
	public var changeGateway: ChangeGateway

	public init(
		getCurrentNetworkID: @escaping GetCurrentNetworkID,
		getGatewayAPIEndpointBaseURL: @escaping GetGatewayAPIEndpointBaseURL,
		getGateways: @escaping GetGateways,
		addGateway: @escaping AddGateway,
		changeGateway: @escaping ChangeGateway
	) {
		self.getCurrentNetworkID = getCurrentNetworkID
		self.getGatewayAPIEndpointBaseURL = getGatewayAPIEndpointBaseURL
		self.getGateways = getGateways
		self.addGateway = addGateway
		self.changeGateway = changeGateway
	}
}

extension GatewaysClient {
	public typealias GetGatewayAPIEndpointBaseURL = @Sendable () async -> URL
	public typealias GetCurrentNetworkID = @Sendable () async -> NetworkID

	public typealias AddGateway = @Sendable (Gateway) async throws -> Void
	public typealias ChangeGateway = @Sendable (Gateway) async throws -> Void

	public typealias GetGateways = @Sendable () async -> Gateways
}
