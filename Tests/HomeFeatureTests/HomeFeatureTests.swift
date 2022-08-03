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

		store.send(.header(.coordinate(.displaySettings)))
		store.receive(.coordinate(.displaySettings))
	}

	func testSettingsButtonTappedFromHeader() {
		let store = TestStore(
			initialState: Home.Header.State(),
			reducer: Home.Header.reducer,
			environment: Home.Header.Environment()
		)

		store.send(.internal(.user(.settingsButtonTapped)))
		store.receive(.coordinate(.displaySettings))
	}
}
