// MARK: - P2PLinksClient
public struct P2PLinksClient: Sendable {
	public var getP2PLinks: GetP2PLinks
	public var updateOrAddP2PLink: UpdateOrAddP2PLink
	public var deleteP2PLinkByPassword: DeleteP2PLinkByPassword
	public var deleteAllP2PLinks: DeleteAllP2PLinks
	public var getP2PLinkPrivateKey: GetP2PLinkPrivateKey
	public var storeP2PLinkPrivateKey: StoreP2PLinkPrivateKey

	public init(
		getP2PLinks: @escaping GetP2PLinks,
		updateOrAddP2PLink: @escaping UpdateOrAddP2PLink,
		deleteP2PLinkByPassword: @escaping DeleteP2PLinkByPassword,
		deleteAllP2PLinks: @escaping DeleteAllP2PLinks,
		getP2PLinkPrivateKey: @escaping GetP2PLinkPrivateKey,
		storeP2PLinkPrivateKey: @escaping StoreP2PLinkPrivateKey
	) {
		self.getP2PLinks = getP2PLinks
		self.updateOrAddP2PLink = updateOrAddP2PLink
		self.deleteP2PLinkByPassword = deleteP2PLinkByPassword
		self.deleteAllP2PLinks = deleteAllP2PLinks
		self.getP2PLinkPrivateKey = getP2PLinkPrivateKey
		self.storeP2PLinkPrivateKey = storeP2PLinkPrivateKey
	}
}

extension P2PLinksClient {
	public typealias GetP2PLinks = @Sendable () async -> P2PLinks
	public typealias UpdateOrAddP2PLink = @Sendable (P2PLink) async throws -> P2PLink?
	public typealias DeleteP2PLinkByPassword = @Sendable (ConnectionPassword) async throws -> Void
	public typealias DeleteAllP2PLinks = @Sendable () async throws -> Void
	public typealias GetP2PLinkPrivateKey = @Sendable (CEPublicKey) async throws -> (privateKey: Curve25519.PrivateKey, isNew: Bool)
	public typealias StoreP2PLinkPrivateKey = @Sendable (CEPublicKey, Curve25519.PrivateKey) async throws -> Void
}
