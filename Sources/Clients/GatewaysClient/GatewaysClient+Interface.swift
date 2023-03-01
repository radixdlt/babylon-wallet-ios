import ClientPrelude
import Profile

// MARK: - GatewaysClient
public struct GatewaysClient: Sendable {
	public var getAllGateways: GetAllGateways
	public var getCurrentGateway: GetCurrentGateway
	public var addGateway: AddGateway
	public var changeGateway: ChangeGateway

	public init(
		getAllGateways: @escaping GetAllGateways,
		getCurrentGateway: @escaping GetCurrentGateway,
		addGateway: @escaping AddGateway,
		changeGateway: @escaping ChangeGateway
	) {
		self.getAllGateways = getAllGateways
		self.getCurrentGateway = getCurrentGateway
		self.addGateway = addGateway
		self.changeGateway = changeGateway
	}
}

extension GatewaysClient {
	public typealias GetCurrentGateway = @Sendable () async -> Gateway
	public typealias GetAllGateways = @Sendable () async -> Gateways.Elements

	public typealias AddGateway = @Sendable (Gateway) async throws -> Void
	public typealias ChangeGateway = @Sendable (Gateway) async throws -> Void
}

extension GatewaysClient {
	public func getCurrentNetworkID() async -> NetworkID {
		await getCurrentGateway().network.id
	}

	public func getGatewayAPIEndpointBaseURL() async -> URL {
		await getCurrentGateway().url
	}
}
