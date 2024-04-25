// MARK: - P2PLinksClient + DependencyKey
extension P2PLinksClient: DependencyKey {
	public typealias Value = P2PLinksClient

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		@Dependency(\.secureStorageClient) var secureStorageClient

		return Self(
			getP2PLinks: {
				(try? secureStorageClient.loadP2PLinks()) ?? []
			},
			updateOrAddP2PLink: { newLink in
				try secureStorageClient.updatingP2PLinks {
					$0.links.updateOrAppend(newLink)
				}
			},
			deleteP2PLinkByPassword: { password in
				try secureStorageClient.updatingP2PLinks {
					$0.links.removeAll(where: { $0.connectionPassword == password })
				}
			},
			deleteAllP2PLinks: {
				try secureStorageClient.updatingP2PLinks {
					$0.links.removeAll()
				}
			},
			getP2PLinkPrivateKey: {
				let privateKey = try secureStorageClient.loadP2PLinksPrivateKey()
				let isNew = privateKey == nil
				return (privateKey ?? Curve25519.PrivateKey(), isNew)
			},
			storeP2PLinkPrivateKey: { privateKey in
				try secureStorageClient.saveP2PLinksPrivateKey(privateKey)
			}
		)
	}

	public static let liveValue: Self = .live()
}

private extension SecureStorageClient {
	@Sendable func updatingP2PLinks<T>(
		_ mutateP2PLinks: @Sendable (inout P2PLinks) throws -> T
	) throws -> T {
		var copy = try loadP2PLinks() ?? []
		let result = try mutateP2PLinks(&copy)
		try saveP2PLinks(copy)
		return result
	}
}
