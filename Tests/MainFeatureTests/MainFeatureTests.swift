import ComposableArchitecture
@testable import MainFeature
import TestUtils

final class MainFeatureTests: TestCase {
	func testTrivial() throws {
		XCTAssertEqual(Main.State(home: .init(wallet: .placeholder)), Main.State(home: .init(wallet: .placeholder)))
	}

	/*
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

	 	store.send(.settings(.internal(.user(.dismissSettings))))
	 	store.receive(.settings(.coordinate(.dismissSettings))) {
	 		$0.settings = nil
	 	}
	 }

	 func testDisplayVisitHub() {
	 	let store = TestStore(
	 initialState: Main.State(home: .placeholder),
	 		reducer: Main.reducer,
	 		environment: .noop
	 	)

	 	store.send(.home(.coordinate(.displayVisitHub)))
	 }

	 func testDisplayCreateAccount() {
	 	let store = TestStore(
	 		initialState: Main.State(),
	 		reducer: Main.reducer,
	 		environment: .noop
	 	)

	 	store.send(.home(.coordinate(.displayCreateAccount))) {
	 		$0.createAccount = .init()
	 	}
	 }

	 func testDismissCreateAccount() {
	 	let store = TestStore(
	 		initialState: Main.State(),
	 		reducer: Main.reducer,
	 		environment: .noop
	 	)

	 	store.send(.createAccount(.coordinate(.dismissCreateAccount))) {
	 		$0.createAccount = nil
	 	}
	 }
	 */
}
