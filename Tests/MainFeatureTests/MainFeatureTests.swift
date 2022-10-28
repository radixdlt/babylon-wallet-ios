import ComposableArchitecture
@testable import MainFeature
import TestUtils

@MainActor
final class MainFeatureTests: TestCase {
	func test_displaySettings_whenCoordinatedToDispaySettings_thenDisplaySettings() async {
		// given
		let store = TestStore(
			initialState: Main.State(networkID: .primary, home: .placeholder),
			reducer: Main.reducer,
			environment: .unimplemented
		)

		// when
		_ = await store.send(.home(.coordinate(.displaySettings))) {
			// then
			$0.settings = .init()
		}
	}

	func test_dismissSettings_whenCoordinatedToDismissSettings_thenDismissSettings() async {
		// given
		let store = TestStore(
			initialState: Main.State(networkID: .primary, home: .placeholder, settings: .init()),
			reducer: Main.reducer,
			environment: .unimplemented
		)

		// when
		_ = await store.send(.settings(.coordinate(.dismissSettings))) {
			// then
			$0.settings = nil
		}
	}
}
