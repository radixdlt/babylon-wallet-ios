import FeatureTestingPrelude
@testable import HomeFeature

@MainActor
final class VisitHubTests: TestCase {
	func testVisitHubButtonTapped() async {
		let store = TestStore(
			initialState: VisitHub.State(),
			reducer: VisitHub()
		)

		await store.send(.view(.visitHubButtonTapped))
		await store.receive(.delegate(.displayHub))
	}
}
