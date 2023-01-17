import FeaturePrelude
@testable import HomeFeature
import TestingPrelude

@MainActor
final class HeaderTests: TestCase {
	func testSettingsButtonTapped() async {
		let store = TestStore(
			initialState: Home.Header.State(),
			reducer: Home.Header()
		)

		await store.send(.internal(.view(.settingsButtonTapped)))
		await store.receive(.delegate(.displaySettings))
	}
}
