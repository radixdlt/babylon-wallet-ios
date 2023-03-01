import AppPreferencesClientLive
import ClientPrelude
import GatewaysClient

extension GatewaysClient: DependencyKey {
	public typealias Value = GatewaysClient

	public static let liveValue: Self = {
		@Dependency(\.appPreferencesClient) var appPreferencesClient

		return Self(
			getCurrentNetworkID: { fatalError() },
			getGatewayAPIEndpointBaseURL: { fatalError() },
			getGateways: { await appPreferencesClient.loadPreferences().gateways },
			addGateway: { _ in },
			changeGateway: { _ in }
		)
	}()
}
