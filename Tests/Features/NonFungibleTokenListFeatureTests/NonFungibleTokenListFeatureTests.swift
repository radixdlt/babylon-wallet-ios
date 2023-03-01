import FeatureTestingPrelude
@testable import NonFungibleTokenListFeature

@MainActor
final class NonFungibleTokenListFeatureTests: TestCase {
	func test_toggleIsExpanded_whenTappedOnHeaderRow_thenToggleBetweenExpanedAndCollapsed() async {
		// given
		var initialState = NonFungibleTokenList.Row.State.previewValue
		initialState.isExpanded = false

		let store = TestStore(
			initialState: initialState,
			reducer: NonFungibleTokenList.Row()
		)

		// when
		await store.send(.view(.isExpandedToggled)) {
			// then
			$0.isExpanded = true
		}

		// when
		await store.send(.view(.isExpandedToggled)) {
			// then
			$0.isExpanded = false
		}
	}
}
