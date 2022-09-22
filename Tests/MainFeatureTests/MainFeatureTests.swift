import ComposableArchitecture
@testable import MainFeature
import TestUtils

@MainActor
final class MainFeatureTests: TestCase {
	func test_removeWallet_whenTappedOnRemoveWallet_thenCoordinateRemovalResult() async {
		// given
		let environment = Main.Environment(
			accountWorthFetcher: .unimplemented,
			appSettingsClient: .unimplemented,
			pasteboardClient: .unimplemented,
			walletRemover: .mock
		)
		let store = TestStore(
			initialState: Main.State(home: .placeholder),
			reducer: Main.reducer,
			environment: environment
		)

		// when
		_ = await store.send(.internal(.user(.removeWallet)))

		// then
		await store.receive(.internal(.system(.removedWallet)))
		await store.receive(.coordinate(.removedWallet))
	}

	func test_displaySettings_whenCoordinatedToDispaySettings_thenDisplaySettings() async {
		// given
		let store = TestStore(
			initialState: Main.State(home: .placeholder),
			reducer: Main.reducer,
			environment: .unimplemented
		)

		// when
		_ = await store.send(.home(.coordinate(.displaySettings))) {
			// then
			$0.settings = .init()
		}
	}

	func test_dismissSettings_whenCoordinatedToDismissSettings_thenDismissSettings() async {
		// given
		let store = TestStore(
			initialState: Main.State(home: .placeholder, settings: .init()),
			reducer: Main.reducer,
			environment: .unimplemented
		)

		// when
		_ = await store.send(.settings(.coordinate(.dismissSettings))) {
			// then
			$0.settings = nil
		}
	}
}
