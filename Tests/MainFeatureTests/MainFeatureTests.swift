import ComposableArchitecture
@testable import MainFeature
import TestUtils

final class MainFeatureTests: TestCase {
	func testDisplaySettings() {
		let store = TestStore(
			initialState: Main.State(wallet: .init(profile: .init())),
			reducer: Main.reducer,
			environment: .init(backgroundQueue: .global(qos: .background), mainQueue: .main, userDefaultsClient: .noop)
		)

		store.send(.home(.coordinate(.displaySettings))) {
			$0.settings = .init()
		}
	}

	func testDismissSettings() {
		let store = TestStore(
			initialState: Main.State(wallet: .init(profile: .init()), settings: .init()),
			reducer: Main.reducer,
			environment: .init(backgroundQueue: .global(qos: .background), mainQueue: .main, userDefaultsClient: .noop)
		)

		store.send(.settings(.coordinate(.dismissSettings))) {
			$0.settings = nil
		}
	}
}
