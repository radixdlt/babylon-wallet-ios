import ClientPrelude
import Profile

// MARK: - P2PClientsClient
public struct P2PClientsClient: Sendable {
	public var getP2PClients: GetP2PClients
	public var addP2PClient: AddP2PClient
	public var deleteP2PClientByID: DeleteP2PClientByID

	public init(
		getP2PClients: @escaping GetP2PClients,
		addP2PClient: @escaping AddP2PClient,
		deleteP2PClientByID: @escaping DeleteP2PClientByID
	) {
		self.getP2PClients = getP2PClients
		self.addP2PClient = addP2PClient
		self.deleteP2PClientByID = deleteP2PClientByID
	}
}

extension P2PClientsClient {
	public typealias GetP2PClients = @Sendable () async -> P2PClients
	public typealias AddP2PClient = @Sendable (P2PClient) async throws -> Void
	public typealias DeleteP2PClientByID = @Sendable (P2PClient.ID) async throws -> Void
}

extension P2PClientsClient {
	public func p2pClient(for id: P2PConnectionID) async throws -> P2PClient? {
		try await getP2PClients().first(where: { $0.id == id })
	}
}
