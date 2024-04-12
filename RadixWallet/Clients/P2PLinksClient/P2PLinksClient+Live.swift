
extension P2PLinksClient: DependencyKey {
	public typealias Value = P2PLinksClient

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		@Dependency(\.appPreferencesClient) var appPreferencesClient

		return Self(
			getP2PLinks: {
//				await appPreferencesClient.getPreferences().p2pLinks
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			addP2PLink: { _ in
//				try await appPreferencesClient.updating {
//					_ = $0.appendP2PLink(newLink)
//				}
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			deleteP2PLinkByPassword: { _ in
//				try await appPreferencesClient.updating {
//					$0.p2pLinks.links.removeAll(where: { $0.connectionPassword == password })
//				}
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			deleteAllP2PLinks: {
//				try await appPreferencesClient.updating {
//					$0.p2pLinks.links.removeAll()
//				}
				sargonProfileFinishMigrateAtEndOfStage1()
			}
		)
	}

	public static let liveValue: Self = .live()
}
