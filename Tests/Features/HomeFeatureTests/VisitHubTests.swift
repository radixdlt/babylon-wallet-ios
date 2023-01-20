import FeatureTestingPrelude
@testable import HomeFeature

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
