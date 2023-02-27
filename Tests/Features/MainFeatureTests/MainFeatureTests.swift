import FeatureTestingPrelude
@testable import MainFeature

@MainActor
final class MainFeatureTests: TestCase {
	func test_displayAndDismissSettings() async {
		// given
		let store = TestStore(
			initialState: Main.State(home: .previewValue),
			reducer: Main()
		)
		store.exhaustivity = .off

		// when
		await store.send(.child(.home(.delegate(.displaySettings)))) {
			// then
			$0.destination = .settings(.init())
		}

		// when
		await store.send(.child(.destination(.presented(.settings(.delegate(.dismiss)))))) {
			// then
			$0.destination = nil
		}
	}
}
