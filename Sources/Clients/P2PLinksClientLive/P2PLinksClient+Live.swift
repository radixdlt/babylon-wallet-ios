import AppPreferencesClient
import ClientPrelude
import P2PLinksClient
import ProfileStore

extension P2PLinksClient: DependencyKey {
	public typealias Value = P2PLinksClient

	public static func live(
		profileStore getProfileStore: @escaping @Sendable () async -> ProfileStore = { await .shared }
	) -> Self {
		@Dependency(\.appPreferencesClient) var appPreferencesClient

		return Self(
			getP2PLinks: {
				await appPreferencesClient.getPreferences().p2pLinks
			},
			addP2PLink: { newClient in
				try await appPreferencesClient.updating {
					_ = $0.appendP2PLink(newClient)
				}
			},
			deleteP2PLinkByPassword: { password in
				try await appPreferencesClient.updating {
					$0.p2pLinks.clients.removeAll(where: { $0.connectionPassword == password })
				}
			},
			deleteAllP2PLinks: {
				try await appPreferencesClient.updating {
					$0.p2pLinks.clients.removeAll()
				}
			}
		)
	}

	public static let liveValue: Self = .live()
}
