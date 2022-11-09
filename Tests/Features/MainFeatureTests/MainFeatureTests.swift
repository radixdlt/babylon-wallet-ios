import ComposableArchitecture
@testable import MainFeature
import TestUtils

@MainActor
final class MainFeatureTests: TestCase {
	func test_displaySettings_whenCoordinatedToDispaySettings_thenDisplaySettings() async {
		// given
		let store = TestStore(
			initialState: Main.State(home: .placeholder),
			reducer: Main.reducer,
			environment: .testValue
		)

		// when
		_ = await store.send(.child(.home(.delegate(.displaySettings)))) {
			// then
			$0.settings = .init()
		}
	}

	func test_dismissSettings_whenCoordinatedToDismissSettings_thenDismissSettings() async {
		// given
		let store = TestStore(
			initialState: Main.State(home: .placeholder, settings: .init()),
			reducer: Main.reducer,
			environment: .testValue
		)

		// when
		_ = await store.send(.child(.settings(.delegate(.dismissSettings)))) {
			// then
			$0.settings = nil
		}
	}
}
