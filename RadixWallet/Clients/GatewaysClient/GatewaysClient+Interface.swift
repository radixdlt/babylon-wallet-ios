import Sargon

// MARK: - GatewaysClient
public struct GatewaysClient: Sendable {
	/// Async sequence of Gateways, emits new value of Gateways
	public var currentGatewayValues: CurrentGatewayValues
	public var gatewaysValues: GatewaysValues
	public var getAllGateways: GetAllGateways
	public var getCurrentGateway: GetCurrentGateway
	public var addGateway: AddGateway
	public var removeGateway: RemoveGateway
	public var changeGateway: ChangeGateway
	public var hasGateway: HasGateway

	public init(
		currentGatewayValues: @escaping CurrentGatewayValues,
		gatewaysValues: @escaping GatewaysValues,
		getAllGateways: @escaping GetAllGateways,
		getCurrentGateway: @escaping GetCurrentGateway,
		addGateway: @escaping AddGateway,
		removeGateway: @escaping RemoveGateway,
		changeGateway: @escaping ChangeGateway,
		hasGateway: @escaping HasGateway
	) {
		self.currentGatewayValues = currentGatewayValues
		self.gatewaysValues = gatewaysValues
		self.getAllGateways = getAllGateways
		self.getCurrentGateway = getCurrentGateway
		self.addGateway = addGateway
		self.removeGateway = removeGateway
		self.changeGateway = changeGateway
		self.hasGateway = hasGateway
	}
}

extension GatewaysClient {
	public typealias CurrentGatewayValues = @Sendable () async -> AnyAsyncSequence<Gateway>
	public typealias GatewaysValues = @Sendable () async -> AnyAsyncSequence<SavedGateways>
	public typealias GetCurrentGateway = @Sendable () async -> Gateway
	public typealias GetAllGateways = @Sendable () async -> Gateways
	public typealias AddGateway = @Sendable (Gateway) async throws -> Void
	public typealias RemoveGateway = @Sendable (Gateway) async throws -> Void
	public typealias ChangeGateway = @Sendable (Gateway) async throws -> Void
	public typealias HasGateway = @Sendable (Url) async -> Bool
}

extension GatewaysClient {
	public func getCurrentNetworkID() async -> NetworkID {
		await getCurrentGateway().network.id
	}

	public func getGatewayAPIEndpointBaseURL() async -> URL {
		await getCurrentGateway().url
	}
}
