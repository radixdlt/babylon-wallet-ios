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
}
