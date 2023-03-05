import AppPreferencesClient
import ClientPrelude
import GatewaysClient
import ProfileStore

extension GatewaysClient: DependencyKey {
	public typealias Value = GatewaysClient

	public static func live(
		profileStore getProfileStore: @escaping @Sendable () async -> ProfileStore = { await ProfileStore.shared() }
	) -> Self {
		@Dependency(\.appPreferencesClient) var appPreferencesClient

		return Self(
			getAllGateways: { await appPreferencesClient.getPreferences().gateways.all },
			getCurrentGateway: { await appPreferencesClient.getPreferences().gateways.current },
			addGateway: { _ in },
			changeGateway: { _ in }
		)
	}

	public static let liveValue: Self = .live()
}
