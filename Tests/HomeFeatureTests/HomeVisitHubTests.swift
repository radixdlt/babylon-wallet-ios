import ComposableArchitecture
@testable import HomeFeature
import TestUtils
import XCTest

final class HomeVisitHubTests: TestCase {
	func testVisitHubButtonTapped() {
		let store = TestStore(
			initialState: Home.VisitHub.State(),
			reducer: Home.VisitHub.reducer,
			environment: Home.VisitHub.Environment()
		)

		store.send(.internal(.user(.visitHubButtonTapped)))
		store.receive(.coordinate(.displayHub))
	}
}
