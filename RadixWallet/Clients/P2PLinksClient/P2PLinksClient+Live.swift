
extension P2PLinksClient: DependencyKey {
	public typealias Value = P2PLinksClient

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		@Dependency(\.appPreferencesClient) var appPreferencesClient

		return Self(
			getP2PLinks: {
				let sargonLinks = await appPreferencesClient.getPreferences().p2pLinks.elements
				return try! P2PLinks(OrderedSet(sargonLinks.map { try P2PLink(connectionPassword: .init(rawValue: HexCodable32Bytes(data: $0.connectionPassword.value.data)), displayName: $0.displayName) }))
			},
			addP2PLink: { newLink in
				try await appPreferencesClient.updating {
					_ = $0.appendP2PLink(newLink)
				}
			},
			deleteP2PLinkByPassword: { _ in
//				try await appPreferencesClient.updating {
//					$0.p2pLinks.links.removeAll(where: { $0.connectionPassword == password })
//				}
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			deleteAllP2PLinks: {
				//                try await appPreferencesClient.updating {
				//                    $0.p2pLinks.links.removeAll()
				//                }
				sargonProfileFinishMigrateAtEndOfStage1()
			}
		)
	}

	public static let liveValue: Self = .live()
}
