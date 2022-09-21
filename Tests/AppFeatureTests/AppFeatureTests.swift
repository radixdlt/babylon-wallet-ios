@testable import AppFeature
import ComposableArchitecture
import SplashFeature
import TestUtils
import Wallet

@MainActor
final class AppFeatureTests: TestCase {
	func test_initialAppState_whenAppLaunches_thenInitialAppStateIsSplash() {
		let appState = App.State()
		let expectedInitialAppState: App.State = .splash(.init())
		XCTAssertEqual(appState, expectedInitialAppState)
	}

	func test_removedWallet_whenWalletRemovedFromMainScreen_thenNavigateToOnboarding() {
		// given
		let initialState = App.State.main(.placeholder)
		let store = TestStore(
			initialState: initialState,
			reducer: App.reducer,
			environment: .unimplemented
		)

		// when
		store.send(.main(.coordinate(.removedWallet))) {
			// then
			$0 = .onboarding(.init())
		}
		store.receive(.coordinate(.onboard))
	}

	func test_onboardedWithWallet_whenWalletCreatedSuccessfullyInOnbnoarding_thenNavigateToMainScreen() {
		// given
		let initialState = App.State.onboarding(.init())
		let wallet = Wallet.placeholder
		let store = TestStore(
			initialState: initialState,
			reducer: App.reducer,
			environment: .unimplemented
		)

		// when
		store.send(.onboarding(.coordinate(.onboardedWithWallet(wallet))))

		// then
		store.receive(.coordinate(.toMain(wallet))) {
			$0 = .main(.init(home: .init(justA: wallet)))
		}
	}

	func test_loadWalletResult_whenWalletLoadedSuccessfullyInSplash_thenNavigateToMainScreen() {
		// given
		let initialState = App.State.splash(.init())
		let wallet = Wallet.placeholder
		let loadWalletResult = SplashLoadWalletResult.walletLoaded(wallet)
		let store = TestStore(
			initialState: initialState,
			reducer: App.reducer,
			environment: .unimplemented
		)

		// when
		store.send(.splash(.coordinate(.loadWalletResult(loadWalletResult))))

		// then
		store.receive(.coordinate(.toMain(wallet))) {
			$0 = .main(.init(home: .init(justA: wallet)))
		}
	}

	func test_loadWalletResult_whenWalletLoadingFailedBecauseDecodingError_thenDoNothingForNow() {
		// given
		let initialState = App.State.splash(.init())
		let reason = "Failed to decode wallet"
		let loadWalletResult = SplashLoadWalletResult.noWallet(reason: reason, failedToDecode: true)
		let store = TestStore(
			initialState: initialState,
			reducer: App.reducer,
			environment: .unimplemented
		)

		// when
		store.send(.splash(.coordinate(.loadWalletResult(loadWalletResult))))

		// then
		// do nothing for now, no state change occured
	}

	func test_loadWalletResult_whenWalletLoadingFailedBecauseNoWalletFound_thenNavigateToOnboarding() async {
		// given
		let initialState = App.State.splash(.init())
		let reason = "Failed to load profile"
		let loadWalletResult = SplashLoadWalletResult.noWallet(reason: reason, failedToDecode: false)
		let store = TestStore(
			initialState: initialState,
			reducer: App.reducer,
			environment: .unimplemented
		)

		// when
		_ = await store.send(.splash(.coordinate(.loadWalletResult(loadWalletResult))))

		// then
		await store.receive(.coordinate(.onboard)) {
			$0 = .onboarding(.init())
		}
	}
}
