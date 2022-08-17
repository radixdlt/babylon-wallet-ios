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

	func testDismissSettings() async {
		let store = TestStore(
			initialState: Main.State(),
			reducer: Main.reducer,
			environment: .init(backgroundQueue: .global(qos: .background), mainQueue: .main, userDefaultsClient: .noop, wallet: .noop)
		)

		await store.send(.settings(.coordinate(.dismissSettings))) {
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

	func testDismissCreateAccount() async {
		let store = TestStore(
			initialState: Main.State(),
			reducer: Main.reducer,
			environment: .init(backgroundQueue: .global(qos: .background), mainQueue: .main, userDefaultsClient: .noop, wallet: .noop)
		)

		await store.send(.createAccount(.coordinate(.dismissCreateAccount))) {
			$0.settings = nil
		}
	}
}
