// MARK: - P2PLinksClient
struct P2PLinksClient {
	var getP2PLinks: GetP2PLinks
	var updateOrAddP2PLink: UpdateOrAddP2PLink
	var updateP2PLink: UpdateP2PLink
	var deleteP2PLinkByPassword: DeleteP2PLinkByPassword
	var deleteAllP2PLinks: DeleteAllP2PLinks
	var getP2PLinkPrivateKey: GetP2PLinkPrivateKey
	var storeP2PLinkPrivateKey: StoreP2PLinkPrivateKey
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
