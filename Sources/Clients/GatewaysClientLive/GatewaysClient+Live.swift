import AppPreferencesClientLive
import ClientPrelude
import GatewaysClient
import ProfileStore

extension GatewaysClient: DependencyKey {
	public typealias Value = GatewaysClient

	public static func live(profileStore: ProfileStore = .shared) -> Self {
		@Dependency(\.appPreferencesClient) var appPreferencesClient

		return Self(
			getAllGateways: { await appPreferencesClient.loadPreferences().gateways.all },
			getCurrentGateway: { await appPreferencesClient.loadPreferences().gateways.current },
			addGateway: { _ in },
			changeGateway: { _ in }
		)
	}

	public static let liveValue: Self = .live()
}
