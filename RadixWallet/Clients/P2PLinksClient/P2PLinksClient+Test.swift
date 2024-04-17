
extension DependencyValues {
	public var p2pLinksClient: P2PLinksClient {
		get { self[P2PLinksClient.self] }
		set { self[P2PLinksClient.self] = newValue }
	}
}

// MARK: - P2PLinksClient + TestDependencyKey
extension P2PLinksClient: TestDependencyKey {
	public static let previewValue = Self.noop
	public static let noop = Self(
		getP2PLinks: { [] },
		updateOrAddP2PLink: { _ in nil },
		deleteP2PLinkByPassword: { _ in },
		deleteAllP2PLinks: {},
		getP2PLinkPrivateKey: { _ in (.init(), false) },
		storeP2PLinkPrivateKey: { _, _ in }
	)
	public static let testValue = Self(
		getP2PLinks: unimplemented("\(Self.self).getP2PLinks"),
		updateOrAddP2PLink: unimplemented("\(Self.self).updateOrAddP2PLink"),
		deleteP2PLinkByPassword: unimplemented("\(Self.self).deleteP2PLinkByPassword"),
		deleteAllP2PLinks: unimplemented("\(Self.self).deleteAllp2pLinks"),
		getP2PLinkPrivateKey: unimplemented("\(Self.self).getP2PLinkPrivateKey"),
		storeP2PLinkPrivateKey: unimplemented("\(Self.self).storeP2PLinkPrivateKey")
	)
}
