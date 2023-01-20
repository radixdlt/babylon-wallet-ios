import FeatureTestingPrelude
@testable import MainFeature

@MainActor
final class MainFeatureTests: TestCase {
	func test_displaySettings_whenCoordinatedToDispaySettings_thenDisplaySettings() async {
		// given
		let store = TestStore(
			initialState: Main.State(home: .previewValue),
			reducer: Main()
		)
		store.exhaustivity = .off

		// when
		await store.send(.child(.home(.delegate(.displaySettings)))) {
			// then
			$0.settings = .init()
		}
	}

	func test_dismissSettings_whenCoordinatedToDismissSettings_thenDismissSettings() async {
		// given
		let store = TestStore(
			initialState: Main.State(home: .previewValue, settings: .init()),
			reducer: Main()
		)

		// when
		await store.send(.child(.settings(.delegate(.dismissSettings)))) {
			// then
			$0.settings = nil
		}
	}
}
