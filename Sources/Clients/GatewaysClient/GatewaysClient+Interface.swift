import ClientPrelude
import Profile

// MARK: - GatewaysClient
public struct GatewaysClient: Sendable {
	/// Async sequence of Gateways, emits new value of Gateways
	public var allGateways: AllGateways
	public var getAllGateways: GetAllGateways
	public var getCurrentGateway: GetCurrentGateway
	public var addGateway: AddGateway
	public var removeGateway: RemoveGateway
	public var changeGateway: ChangeGateway

	public init(
		allGateways: @escaping AllGateways,
		getAllGateways: @escaping GetAllGateways,
		getCurrentGateway: @escaping GetCurrentGateway,
		addGateway: @escaping AddGateway,
		removeGateway: @escaping RemoveGateway,
		changeGateway: @escaping ChangeGateway
	) {
		self.allGateways = allGateways
		self.getAllGateways = getAllGateways
		self.getCurrentGateway = getCurrentGateway
		self.addGateway = addGateway
		self.removeGateway = removeGateway
		self.changeGateway = changeGateway
	}
}

extension GatewaysClient {
	public typealias AllGateways = @Sendable () async -> AnyAsyncSequence<Gateways>
	public typealias GetCurrentGateway = @Sendable () async -> Radix.Gateway
	public typealias GetAllGateways = @Sendable () async -> Gateways.Elements
	public typealias AddGateway = @Sendable (Radix.Gateway) async throws -> Void
	public typealias RemoveGateway = @Sendable (Radix.Gateway) async throws -> Void
	public typealias ChangeGateway = @Sendable (Radix.Gateway) async throws -> Void
}

extension GatewaysClient {
	public func getCurrentNetworkID() async -> NetworkID {
		await getCurrentGateway().network.id
	}

	public func getGatewayAPIEndpointBaseURL() async -> URL {
		await getCurrentGateway().url
	}
}
