import ClientPrelude

extension DependencyValues {
	public var p2pLinkssClient: P2PLinksClient {
		get { self[P2PLinksClient.self] }
		set { self[P2PLinksClient.self] = newValue }
	}
}

// MARK: - P2PLinksClient + TestDependencyKey
extension P2PLinksClient: TestDependencyKey {
	public static let previewValue: Self = .noop
	public static let noop = Self(
		getP2PLinks: { [] },
		addP2PLink: { _ in },
		deleteP2PLinkByPassword: { _ in },
		deleteAllP2PLinks: {}
	)
	public static let testValue = Self(
		getP2PLinks: unimplemented("\(Self.self).getP2PLinks"),
		addP2PLink: unimplemented("\(Self.self).addP2PLink"),
		deleteP2PLinkByPassword: unimplemented("\(Self.self).deleteP2PLinkByPassword"),
		deleteAllP2PLinks: unimplemented("\(Self.self).deleteAllp2pLinkss")
	)
}
