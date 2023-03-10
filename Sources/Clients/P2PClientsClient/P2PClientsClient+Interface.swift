import RadixConnectModels

// MARK: - P2PLinksClient
public struct P2PLinksClient: Sendable {
	public var getP2PLinks: GetP2PLinks
	public var addP2PLink: AddP2PLink
	public var deleteP2PLinkByPassword: DeleteP2PLinkByPassword
	public var deleteAllP2PLinks: DeleteAllP2PLinks

	public init(
		getP2PLinks: @escaping GetP2PLinks,
		addP2PLink: @escaping AddP2PLink,
		deleteP2PLinkByPassword: @escaping DeleteP2PLinkByPassword,
		deleteAllP2PLinks: @escaping DeleteAllP2PLinks
	) {
		self.getP2PLinks = getP2PLinks
		self.addP2PLink = addP2PLink
		self.deleteP2PLinkByPassword = deleteP2PLinkByPassword
		self.deleteAllP2PLinks = deleteAllP2PLinks
	}
}

extension P2PLinksClient {
	public typealias GetP2PLinks = @Sendable () async -> P2PLinks
	public typealias AddP2PLink = @Sendable (P2PLink) async throws -> Void
	public typealias DeleteP2PLinkByPassword = @Sendable (ConnectionPassword) async throws -> Void
	public typealias DeleteAllP2PLinks = @Sendable () async throws -> Void
}
