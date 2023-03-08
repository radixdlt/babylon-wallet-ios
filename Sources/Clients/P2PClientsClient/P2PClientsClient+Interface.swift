import RadixConnectModels

// MARK: - P2PClientsClient
public struct P2PClientsClient: Sendable {
	public var getP2PClients: GetP2PClients
	public var addP2PClient: AddP2PClient
	public var deleteP2PClientByPassword: DeleteP2PClientByPassword
	public var deleteAllP2PClients: DeleteAllP2PClients

	public init(
		getP2PClients: @escaping GetP2PClients,
		addP2PClient: @escaping AddP2PClient,
		deleteP2PClientByPassword: @escaping DeleteP2PClientByPassword,
		deleteAllP2PClients: @escaping DeleteAllP2PClients
	) {
		self.getP2PClients = getP2PClients
		self.addP2PClient = addP2PClient
		self.deleteP2PClientByPassword = deleteP2PClientByPassword
		self.deleteAllP2PClients = deleteAllP2PClients
	}
}

extension P2PClientsClient {
	public typealias GetP2PClients = @Sendable () async -> P2PClients
	public typealias AddP2PClient = @Sendable (P2PClient) async throws -> Void
	public typealias DeleteP2PClientByPassword = @Sendable (ConnectionPassword) async throws -> Void
	public typealias DeleteAllP2PClients = @Sendable () async throws -> Void
}
