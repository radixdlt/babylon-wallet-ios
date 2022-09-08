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

/*
	func testLoadWalletResult() {
		let store = TestStore(
			initialState: App.State.splash(.init()),
			reducer: App.reducer,
			environment: environment
		)

		let wallet = Wallet(profile: .init(), deviceFactorTypeMnemonic: "")
		let loadWalletResult = SplashLoadWalletResult.walletLoaded(wallet)
		store.send(.splash(.coordinate(.loadWalletResult(loadWalletResult))))
		//        {
//			$0 = .main(.init(home: .init(justA: wallet)))
//		}
		store.receive(.coordinate(.toMain(wallet)))
	}
*/
}
