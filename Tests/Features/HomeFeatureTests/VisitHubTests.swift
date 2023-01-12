import FeaturePrelude
@testable import HomeFeature
import TestUtils

@MainActor
final class VisitHubTests: TestCase {
	func testVisitHubButtonTapped() async {
		let store = TestStore(
			initialState: Home.VisitHub.State(),
			reducer: Home.VisitHub()
		)

		await store.send(.internal(.view(.visitHubButtonTapped)))
		await store.receive(.delegate(.displayHub))
	}
}
