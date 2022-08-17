import ComposableArchitecture
@testable import HomeFeature
import TestUtils
import XCTest

final class HomeAggregatedValueTests: TestCase {
	func testVisibilityButtonTapped() {
		let store = TestStore(
			initialState: Home.AggregatedValue.State(account: .placeholder, isVisible: false),
			reducer: Home.AggregatedValue.reducer,
			environment: Home.AggregatedValue.Environment()
		)

		store.send(.internal(.user(.toggleVisibilityButtonTapped))) {
			$0.isVisible = true
		}

		store.send(.internal(.user(.toggleVisibilityButtonTapped))) {
			$0.isVisible = false
		}
	}
}
