import ComposableArchitecture
@testable import HomeFeature
import TestUtils
import XCTest

final class HomeFeatureTests: TestCase {
	func testSettingsButtonTapped() {
		let store = TestStore(
			initialState: Home.State(),
			reducer: Home.reducer,
			environment: Home.Environment()
		)

		store.send(.header(.internal(.user(.settingsButtonTapped))))
		store.receive(.header(.coordinate(.displaySettings)))
		store.receive(.coordinate(.displaySettings))
	}
}
