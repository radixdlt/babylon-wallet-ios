import ComposableArchitecture
@testable import HomeFeature
import TestUtils
import XCTest

final class HomeBalanceTests: TestCase {
	func testVisibilityButtonTapped() {
		let store = TestStore(
			initialState: Home.Balance.State(),
			reducer: Home.Balance.reducer,
			environment: Home.Balance.Environment()
		)

		store.send(.internal(.user(.toggleVisibilityButtonTapped))) {
			$0.isVisible = true
		}

		store.send(.internal(.user(.toggleVisibilityButtonTapped))) {
			$0.isVisible = false
		}
	}
}
