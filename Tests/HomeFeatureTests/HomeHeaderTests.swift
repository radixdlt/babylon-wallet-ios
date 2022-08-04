import ComposableArchitecture
@testable import HomeFeature
import TestUtils
import XCTest

final class HomeHeaderTests: TestCase {
	func testSettingsButtonTapped() {
		let store = TestStore(
			initialState: Home.Header.State(),
			reducer: Home.Header.reducer,
			environment: Home.Header.Environment()
		)

		store.send(.internal(.user(.settingsButtonTapped)))
		store.receive(.coordinate(.displaySettings))
	}
}
