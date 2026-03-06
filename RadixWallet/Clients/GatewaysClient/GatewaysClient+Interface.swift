import Sargon

// MARK: - GatewaysClient
struct GatewaysClient {
	/// Async sequence of Gateways, emits new value of Gateways
	var currentGatewayValues: CurrentGatewayValues
	var gatewaysValues: GatewaysValues
	var getAllGateways: GetAllGateways
	var getCurrentGateway: GetCurrentGateway
	var addGateway: AddGateway
	var removeGateway: RemoveGateway
	var changeGateway: ChangeGateway
	var hasGateway: HasGateway
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
