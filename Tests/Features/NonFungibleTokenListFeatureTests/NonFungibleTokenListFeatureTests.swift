import ComposableArchitecture
import Foundation
@testable import NonFungibleTokenListFeature
import TestUtils

@MainActor
final class NonFungibleTokenListFeatureTests: TestCase {
	func test_toggleIsExpanded_whenTappedOnHeaderRow_thenToggleBetweenExpanedAndCollapsed() async {
		// given
		var initialState = NonFungibleTokenList.Row.RowState(containers: [])
		initialState.isExpanded = false

		let store = TestStore(
			initialState: initialState,
			reducer: NonFungibleTokenList.Row.reducer,
			environment: .testValue
		)

		// when
		_ = await store.send(.internal(.view(.isExpandedToggled))) {
			// then
			$0.isExpanded = true
		}

		// when
		_ = await store.send(.internal(.view(.isExpandedToggled))) {
			// then
			$0.isExpanded = false
		}
	}
}
