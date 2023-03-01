import ClientPrelude
import Profile

// MARK: - P2PClientsClient
public struct P2PClientsClient: Sendable {
	public var getP2PClients: GetP2PClients
	public var addP2PClient: AddP2PClient

	public init(
		getP2PClients: @escaping GetP2PClients,
		addP2PClient: @escaping AddP2PClient
	) {
		self.getP2PClients = getP2PClients
		self.addP2PClient = addP2PClient
	}
}

extension P2PClientsClient {
	public typealias GetP2PClients = @Sendable () async -> P2PClients
	public typealias AddP2PClient = @Sendable (P2PClient) async throws -> Void
}
