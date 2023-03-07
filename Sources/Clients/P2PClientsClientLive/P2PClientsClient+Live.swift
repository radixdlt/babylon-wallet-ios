import AppPreferencesClient
import ClientPrelude
import P2PClientsClient
import ProfileStore

extension P2PClientsClient: DependencyKey {
	public typealias Value = P2PClientsClient

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		@Dependency(\.appPreferencesClient) var appPreferencesClient

		return Self(
			getP2PClients: {
				await appPreferencesClient.getPreferences().p2pClients
			},
			addP2PClient: { newClient in
				try await appPreferencesClient.updating {
					_ = $0.appendP2PClient(newClient)
				}
			},
			deleteP2PClientByPassword: { password in
				try await appPreferencesClient.updating {
                                        $0.p2pClients.clients.removeAll(where: { $0.connectionPassword == password })
				}
			}
		)
	}

	public static let liveValue: Self = .live()
}
