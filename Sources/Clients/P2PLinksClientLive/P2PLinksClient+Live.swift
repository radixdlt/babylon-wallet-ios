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
			addP2PLink: { newLink in
				try await appPreferencesClient.updating {
					_ = $0.appendP2PLink(newLink)
				}
			},
			deleteP2PLinkByPassword: { password in
				try await appPreferencesClient.updating {
					$0.p2pLinks.links.removeAll(where: { $0.connectionPassword == password })
				}
			},
			deleteAllP2PLinks: {
				try await appPreferencesClient.updating {
					$0.p2pLinks.links.removeAll()
				}
			}
		)
	}

	public static let liveValue: Self = .live()
}
