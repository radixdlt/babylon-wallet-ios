import ComposableArchitecture
@testable import HomeFeature
import TestUtils

final class HeaderTests: TestCase {
	func testSettingsButtonTapped() {
		let store = TestStore(
			initialState: Home.Header.State(),
			reducer: Home.Header.reducer,
			environment: Home.Header.Environment()
		)

		store.send(.internal(.view(.settingsButtonTapped)))
		store.receive(.delegate(.displaySettings))
	}
}
