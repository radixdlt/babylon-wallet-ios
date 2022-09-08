@testable import AppFeature
import ComposableArchitecture
import SplashFeature
import TestUtils
import Wallet

final class AppFeatureTests: TestCase {
	let environment = App.Environment(
		backgroundQueue: .unimplemented,
		mainQueue: .unimplemented,
		appSettingsClient: .mock,
		accountWorthFetcher: .mock,
		pasteboardClient: .noop,
		profileLoader: .noop,
		userDefaultsClient: .unimplemented,
		walletLoader: .noop
	)

	func testRemovedWallet() {
		let store = TestStore(
			initialState: App.State.main(.placeholder),
			reducer: App.reducer,
			environment: environment
		)

		store.send(.main(.coordinate(.removedWallet))) {
			$0 = .onboarding(.init())
		}
		store.receive(.coordinate(.onboard))
	}

	func testOnboardedWithWallet() {
		let store = TestStore(
			initialState: App.State.onboarding(.init()),
			reducer: App.reducer,
			environment: environment
		)

		let wallet = Wallet(profile: .init(), deviceFactorTypeMnemonic: "")
		store.send(.onboarding(.coordinate(.onboardedWithWallet(wallet)))) {
			$0 = .main(.init(home: .init(wallet: wallet)))
		}
		store.receive(.coordinate(.toMain(wallet)))
	}

	func testLoadWalletResultLoadedWallet() {
		let store = TestStore(
			initialState: App.State.splash(.init()),
			reducer: App.reducer,
			environment: environment
		)

		let wallet = Wallet(profile: .init(), deviceFactorTypeMnemonic: "")
		let loadWalletResult = SplashLoadWalletResult.walletLoaded(wallet)
		store.send(.splash(.coordinate(.loadWalletResult(loadWalletResult))))
		store.receive(.coordinate(.toMain(wallet))) {
			$0 = .main(.init(home: .init(justA: wallet)))
		}
	}

	func testLoadWalletResultNoWallet() {
		let store = TestStore(
			initialState: App.State.splash(.init()),
			reducer: App.reducer,
			environment: environment
		)

		let reason = "No wallet"
		let loadWalletResult = SplashLoadWalletResult.noWallet(reason: reason)
		store.send(.splash(.coordinate(.loadWalletResult(loadWalletResult)))) {
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

	func testCoordinateOnboard() {
		let store = TestStore(
			initialState: App.State.splash(.init()),
			reducer: App.reducer,
			environment: environment
		)

		store.send(.coordinate(.onboard)) {
			$0 = .onboarding(.init())
		}
	}

	func testCoordinateToMain() {
		let store = TestStore(
			initialState: App.State.onboarding(.init()),
			reducer: App.reducer,
			environment: environment
		)

		let wallet = Wallet(profile: .init(), deviceFactorTypeMnemonic: "")
		store.send(.coordinate(.toMain(wallet))) {
			$0 = .main(.init(home: .init(justA: wallet)))
		}
	}

	func testDismissAlert() {
		let store = TestStore(
			initialState: App.State.alert(.init(title: .init("Alert"))),
			reducer: App.reducer,
			environment: environment
		)

		store.send(.internal(.user(.alertDismissed))) {
			$0 = .alert(nil)
		}
	}
}
