import ComposableArchitecture
@testable import MainFeature
import TestUtils

final class MainFeatureTests: TestCase {
	func testDisplaySettings() {
		let store = TestStore(
			initialState: Main.State(),
			reducer: Main.reducer,
			environment: .init(backgroundQueue: .global(qos: .background), mainQueue: .main, userDefaultsClient: .noop, wallet: .noop)
		)

		store.send(.home(.coordinate(.displaySettings))) {
			$0.settings = .init()
		}
	}

	func testDismissSettings() {
		let store = TestStore(
			initialState: Main.State(),
			reducer: Main.reducer,
			environment: .init(backgroundQueue: .global(qos: .background), mainQueue: .main, userDefaultsClient: .noop, wallet: .noop)
		)

		store.send(.settings(.coordinate(.dismissSettings))) {
			$0.settings = nil
		}
	}

	func testDisplayVisitHub() {
		let store = TestStore(
			initialState: Main.State(),
			reducer: Main.reducer,
			environment: .init(backgroundQueue: .global(qos: .background), mainQueue: .main, userDefaultsClient: .noop, wallet: .noop)
		)

		store.send(.home(.coordinate(.displayVisitHub)))
	}

	func testDisplayCreateAccount() {
		let store = TestStore(
			initialState: Main.State(),
			reducer: Main.reducer,
			environment: .init(backgroundQueue: .global(qos: .background), mainQueue: .main, userDefaultsClient: .noop, wallet: .noop)
		)

		store.send(.home(.coordinate(.displayCreateAccount))) {
			$0.createAccount = .init()
		}
	}

	func testDismissCreateAccount() {
		let store = TestStore(
			initialState: Main.State(),
			reducer: Main.reducer,
			environment: .init(backgroundQueue: .global(qos: .background), mainQueue: .main, userDefaultsClient: .noop, wallet: .noop)
		)

		store.send(.createAccount(.coordinate(.dismissCreateAccount))) {
			$0.createAccount = nil
		}
	}
}
