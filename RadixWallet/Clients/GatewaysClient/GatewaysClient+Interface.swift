import Sargon

// MARK: - GatewaysClient
struct GatewaysClient: Sendable {
	/// Async sequence of Gateways, emits new value of Gateways
	var currentGatewayValues: CurrentGatewayValues
	var gatewaysValues: GatewaysValues
	var getAllGateways: GetAllGateways
	var getCurrentGateway: GetCurrentGateway
	var addGateway: AddGateway
	var removeGateway: RemoveGateway
	var changeGateway: ChangeGateway
	var hasGateway: HasGateway

	init(
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
	typealias CurrentGatewayValues = @Sendable () async -> AnyAsyncSequence<Gateway>
	typealias GatewaysValues = @Sendable () async -> AnyAsyncSequence<SavedGateways>
	typealias GetCurrentGateway = @Sendable () async -> Gateway
	typealias GetAllGateways = @Sendable () async -> Gateways
	typealias AddGateway = @Sendable (Gateway) async throws -> Void
	typealias RemoveGateway = @Sendable (Gateway) async throws -> Void
	typealias ChangeGateway = @Sendable (Gateway) async throws -> Void
	typealias HasGateway = @Sendable (FfiUrl) async -> Bool
}

extension GatewaysClient {
	func getCurrentNetworkID() async -> NetworkID {
		await getCurrentGateway().network.id
	}

	func getGatewayAPIEndpointBaseURL() async -> URL {
		await getCurrentGateway().url
	}
}
