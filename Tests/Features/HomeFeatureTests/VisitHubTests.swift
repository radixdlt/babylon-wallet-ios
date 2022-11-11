import ComposableArchitecture
@testable import HomeFeature
import TestUtils

final class VisitHubTests: TestCase {
	func testVisitHubButtonTapped() {
		let store = TestStore(
			initialState: Home.VisitHub.State(),
			reducer: Home.VisitHub()
		)

		store.send(.internal(.view(.visitHubButtonTapped)))
		store.receive(.delegate(.displayHub))
	}
}
