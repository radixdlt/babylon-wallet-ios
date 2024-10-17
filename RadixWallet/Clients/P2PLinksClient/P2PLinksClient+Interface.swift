// MARK: - P2PLinksClient
struct P2PLinksClient: Sendable {
	var getP2PLinks: GetP2PLinks
	var updateOrAddP2PLink: UpdateOrAddP2PLink
	var updateP2PLink: UpdateP2PLink
	var deleteP2PLinkByPassword: DeleteP2PLinkByPassword
	var deleteAllP2PLinks: DeleteAllP2PLinks
	var getP2PLinkPrivateKey: GetP2PLinkPrivateKey
	var storeP2PLinkPrivateKey: StoreP2PLinkPrivateKey

	init(
		getP2PLinks: @escaping GetP2PLinks,
		updateOrAddP2PLink: @escaping UpdateOrAddP2PLink,
		updateP2PLink: @escaping UpdateP2PLink,
		deleteP2PLinkByPassword: @escaping DeleteP2PLinkByPassword,
		deleteAllP2PLinks: @escaping DeleteAllP2PLinks,
		getP2PLinkPrivateKey: @escaping GetP2PLinkPrivateKey,
		storeP2PLinkPrivateKey: @escaping StoreP2PLinkPrivateKey
	) {
		self.getP2PLinks = getP2PLinks
		self.updateOrAddP2PLink = updateOrAddP2PLink
		self.updateP2PLink = updateP2PLink
		self.deleteP2PLinkByPassword = deleteP2PLinkByPassword
		self.deleteAllP2PLinks = deleteAllP2PLinks
		self.getP2PLinkPrivateKey = getP2PLinkPrivateKey
		self.storeP2PLinkPrivateKey = storeP2PLinkPrivateKey
	}
}

extension P2PLinksClient {
	typealias GetP2PLinks = @Sendable () async -> P2PLinks
	typealias UpdateOrAddP2PLink = @Sendable (P2PLink) async throws -> P2PLink?
	typealias UpdateP2PLink = @Sendable (P2PLink) async throws -> Void
	typealias DeleteP2PLinkByPassword = @Sendable (RadixConnectPassword) async throws -> Void
	typealias DeleteAllP2PLinks = @Sendable () async throws -> Void
	typealias GetP2PLinkPrivateKey = @Sendable () async throws -> (privateKey: Curve25519.PrivateKey, isNew: Bool)
	typealias StoreP2PLinkPrivateKey = @Sendable (Curve25519.PrivateKey) async throws -> Void
}

extension P2PLinksClient {
	func hasP2PLinks() async -> Bool {
		await !getP2PLinks().isEmpty
	}
}
