@testable import AppFeature
import ComposableArchitecture
import SplashFeature
import TestUtils
import Wallet

final class AppFeatureTests: TestCase {
	let environment = App.Environment(
		backgroundQueue: .unimplemented,
		mainQueue: .unimplemented,
		appSettingsClient: .unimplemented,
		accountWorthFetcher: .unimplemented,
		pasteboardClient: .unimplemented,
		profileLoader: .unimplemented,
		userDefaultsClient: .unimplemented,
		walletLoader: .unimplemented
	)

	func test_removedWallet_whenWalletRemovedFromMainScreen_thenNavigateToOnboarding() {
		// given
		let initialState = App.State.main(.placeholder)
		let store = TestStore(
			initialState: initialState,
			reducer: App.reducer,
			environment: environment
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
			environment: environment
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
			environment: environment
		)

		// when
		store.send(.splash(.coordinate(.loadWalletResult(loadWalletResult))))

		// then
		store.receive(.coordinate(.toMain(wallet))) {
			$0 = .main(.init(home: .init(justA: wallet)))
		}
	}

	func test_loadWalletResult_whenWalletLoadingFailedInSplash_thenDisplayAlert() {
		// given
		let initialState = App.State.splash(.init())
		let reason = "No wallet"
		let loadWalletResult = SplashLoadWalletResult.noWallet(reason: reason)
		let store = TestStore(
			initialState: initialState,
			reducer: App.reducer,
			environment: environment
		)

		// when
		store.send(.splash(.coordinate(.loadWalletResult(loadWalletResult)))) {
			// then
			$0 = .alert(.init(
				title: TextState(reason),
				buttons: [
					.cancel(
						TextState("OK, I'll onboard"),
						action: .send(.coordinate(.onboard))
					),
				]
			))
		}
	}

	func test_coordinateOnboard_whenNoWalletLoadedInSplash_thenNavigateToOnboarding() {
		// given
		let initialState = App.State.splash(.init())
		let store = TestStore(
			initialState: initialState,
			reducer: App.reducer,
			environment: environment
		)

		// when
		store.send(.coordinate(.onboard)) {
			// then
			$0 = .onboarding(.init())
		}
	}

	func test_dismissAlert_whenTapOnDismissPresentedAlert_thenHideAlert() {
		// given
		let initialState = App.State.alert(.init(title: .init("Alert")))
		let store = TestStore(
			initialState: initialState,
			reducer: App.reducer,
			environment: environment
		)

		// when
		store.send(.internal(.user(.alertDismissed))) {
			// then
			$0 = .alert(nil)
		}
	}
}
