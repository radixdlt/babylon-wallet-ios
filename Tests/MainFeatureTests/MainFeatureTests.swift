import ComposableArchitecture
@testable import MainFeature
import TestUtils

final class MainFeatureTests: TestCase {
	@MainActor func testRemoveWallet() async {
		let store = TestStore(
			initialState: Main.State(home: .placeholder),
			reducer: Main.reducer,
			environment: .noop
		)

		await store.send(.internal(.user(.removeWallet)))
		await store.receive(.internal(.system(.removedWallet)))
		await store.receive((.coordinate(.removedWallet)))
	}

	@MainActor func testRemovedWallet() async {
		let store = TestStore(
			initialState: Main.State(home: .placeholder),
			reducer: Main.reducer,
			environment: .noop
		)

		await store.send(.internal(.system(.removedWallet)))
		await store.receive(.coordinate(.removedWallet))
	}

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
