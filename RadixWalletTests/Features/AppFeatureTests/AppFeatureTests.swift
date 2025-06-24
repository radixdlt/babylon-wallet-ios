@testable import Radix_Wallet_Dev
import Sargon
import XCTest

// MARK: - AppFeatureTests
@MainActor
final class AppFeatureTests: TestCase {
	let networkID = NetworkID.nebunet

	func test_initialAppState_whenAppLaunches_thenInitialAppStateIsSplash() {
		let appState = App.State()
		XCTAssertEqual(appState.root, .splash(.init()))
	}

	func test_removedWallet_whenWalletRemovedFromMainScreen_thenNavigateToOnboarding() async {
		// given
		let store = TestStore(
			initialState: App.State(root: .main(.init(
				home: .init(),
				dAppsDirectory: .init(),
				discover: .init(),
				settings: .init()
			))),
			reducer: App.init
		) {
			$0.gatewaysClient.gatewaysValues = { AsyncLazySequence([.init(current: .mainnet)]).eraseToAnyAsyncSequence() }
			$0.deepLinkHandlerClient = .noop
		}
		// when
		await store.send(.internal(.didResetWallet)) {
			$0.root = .onboardingCoordinator(.init())
		}
	}

	func test__GIVEN__splash__WHEN__loadProfile_results_in_noProfile__THEN__navigate_to_onboarding() async {
		// given
		let clock = TestClock()
		let store = TestStore(
			initialState: App.State(root: .splash(.init())),
			reducer: App.init
		) {
			$0.errorQueue = .liveValue
			$0.continuousClock = clock
			$0.deepLinkHandlerClient = .noop
		}

		// then
		await store.send(.child(.splash(.delegate(.completed(.none))))) {
			$0.root = .onboardingCoordinator(.init())
		}

		await clock.run() // fast-forward clock to the end of time
	}
}
