import ComposableArchitecture
@testable import MainFeature
import TestUtils

@MainActor
final class MainFeatureTests: TestCase {
	func test_displaySettings_whenCoordinatedToDispaySettings_thenDisplaySettings() async {
		// given
		let store = TestStore(
			initialState: Main.State(home: .placeholder),
			reducer: Main()
		)
		store.exhaustivity = .off

		// when
		_ = await store.send(.child(.home(.delegate(.displaySettings)))) {
			// then
			$0.settings = .init()
		}
	}

	func test_dismissSettings_whenCoordinatedToDismissSettings_thenDismissSettings_and_trigger_viewDidAppear_on_home_to_reload_p2pclients() async {
		// given
		let store = TestStore(
			initialState: Main.State(home: .placeholder, settings: .init()),
			reducer: Main()
		)
		store.exhaustivity = .off
		store.dependencies.appSettingsClient.loadSettings = { .default }
		store.dependencies.profileClient.getAccounts = { .init(rawValue: [.mocked0])! }
		store.dependencies.p2pConnectivityClient.getP2PClients = { [] }
		store.dependencies.accountPortfolioFetcher.fetchPortfolio = { _ in [:] }

		// when
		_ = await store.send(.child(.settings(.delegate(.dismissSettings)))) {
			// then
			$0.settings = nil
		}
		await store.receive(.child(.home(.view(.didAppear))))
	}
}
