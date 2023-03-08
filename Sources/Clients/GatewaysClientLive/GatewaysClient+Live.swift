import AppPreferencesClient
import ClientPrelude
import GatewaysClient
import ProfileStore

extension GatewaysClient: DependencyKey {
	public typealias Value = GatewaysClient

	public static func live(
		profileStore getProfileStore: @escaping @Sendable () async -> ProfileStore = { await .shared }
	) -> Self {
		@Dependency(\.appPreferencesClient) var appPreferencesClient

		return Self(
			getAllGateways: { await appPreferencesClient.getPreferences().gateways.all },
			getCurrentGateway: { await appPreferencesClient.getPreferences().gateways.current },
			addGateway: { gateway in
				try await getProfileStore().updating { profile in
					try profile.addNewGateway(gateway)
				}
			},
			changeGateway: { gateway in
				try await getProfileStore().updating { profile in
					try profile.changeGateway(to: gateway)
				}
			}
		)
	}

	public static let liveValue: Self = .live()
}
