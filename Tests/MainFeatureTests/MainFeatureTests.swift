import ComposableArchitecture
@testable import MainFeature
import TestUtils

final class MainFeatureTests: TestCase {
	/*
	 func testRemoveWallet(){
	 	let store = TestStore(
	 		initialState: Main.State(home: .placeholder),
	 		reducer: Main.reducer,
	 		environment: .noop
	 	)

	 	store.send(.internal(.user(.removeWallet)))
	 	store.receive(.internal(.system(.removedWallet)))
	 }
	 */

	/*
	 func testRemovedWallet() {
	 	let store = TestStore(
	 		initialState: Main.State(home: .placeholder),
	 		reducer: Main.reducer,
	 		environment: .noop
	 	)

	 	store.send(.internal(.system(.removedWallet)))
	 	store.receive(.coordinate(.removedWallet))
	 }
	 */

	func testDisplaySettings() {
		let store = TestStore(
			initialState: Main.State(home: .placeholder),
			reducer: Main.reducer,
			environment: .noop
		)

		store.send(.home(.coordinate(.displaySettings))) {
			$0.settings = .init()
		}
	}

	func testDismissSettings() {
		let store = TestStore(
			initialState: Main.State(home: .placeholder, settings: .init()),
			reducer: Main.reducer,
			environment: .noop
		)

		store.send(.settings(.coordinate(.dismissSettings))) {
			$0.settings = nil
		}
	}
}
