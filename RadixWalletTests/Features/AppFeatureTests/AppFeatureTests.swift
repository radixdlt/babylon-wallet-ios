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
			initialState: App.State(root: .main(.init(home: .init(), settings: .init(), dAppsDirectory: .init()))),
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

	func test_splash__GIVEN__an_existing_profile__WHEN__existing_profile_loaded__THEN__we_navigate_to_main() async throws {
		// GIVEN: an existing profile
		let accountRecoveryNeeded = true
		let clock = TestClock()
		let store = TestStore(
			initialState: App.State(root: .splash(.init())),
			reducer: App.init
		) {
			$0.errorQueue.errors = { AsyncLazySequence([]).eraseToAnyAsyncSequence() }
			$0.continuousClock = clock

			$0.deviceFactorSourceClient.isAccountRecoveryNeeded = {
				accountRecoveryNeeded
			}
		}

		// THEN: navigate to main
		await store.send(.child(.splash(.delegate(.completed(.loaded(Profile.withOneAccount)))))) {
			$0.root = .main(.init(home: .init(), dAppDirectory: .init(), settings: .init()))
		}

		await clock.run() // fast-forward clock to the end of time
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
