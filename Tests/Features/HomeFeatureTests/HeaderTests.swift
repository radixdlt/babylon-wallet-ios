import FeatureTestingPrelude
@testable import HomeFeature

@MainActor
final class HeaderTests: TestCase {
	func testSettingsButtonTapped() async {
		let store = TestStore(
			initialState: Header.State(accountRecoveryIsNeeded: false),
			reducer: Header()
		)

		await store.send(.view(.settingsButtonTapped))
		await store.receive(.delegate(.displaySettings))
	}
}
