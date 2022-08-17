import ComposableArchitecture
import MainFeature
import OnboardingFeature
import ProfileLoader
import SplashFeature
import UserDefaultsClient
import Wallet
import WalletLoader

public extension App {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>

	static let reducer = Reducer.combine(
		Main.reducer
			.optional()
			.pullback(
				state: /App.State.main,
				action: /Action.main,
				environment: {
					Main.Environment(
						userDefaultsClient: $0.userDefaultsClient,
						// FIXME: wallet
						//                        wallet: $0.walletLoader.loadWallet
						wallet: .placeholder
					)
				}
			),

		Onboarding.reducer
			.optional()
			.pullback(
				state: /App.State.onboarding,
				action: /Action.onboarding,
				environment: {
					Onboarding.Environment(
						backgroundQueue: $0.backgroundQueue,
						mainQueue: $0.mainQueue,
						userDefaultsClient: $0.userDefaultsClient
					)
				}
			),

		Splash.reducer
			.optional()
			.pullback(
				state: /App.State.splash,
				action: /Action.splash,
				environment: {
					Splash.Environment(
						backgroundQueue: $0.backgroundQueue,
						mainQueue: $0.mainQueue,
						profileLoader: $0.profileLoader,
						walletLoader: $0.walletLoader
					)
				}
			),

		appReducer
	)
	.debug()

	static let appReducer = Reducer { state, action, _ in
		switch action {
		case .main(.coordinate(.removedWallet)):
			state = .onboarding(.init())
			return Effect(value: .coordinate(.onboard))
		case .main:
			return .none
		case let .onboarding(.coordinate(.onboardedWithWallet(wallet))):
			// FIXME: wallet
//			state = .main(.init(wallet: wallet))
			state = .main(.placeholder)
			return Effect(value: .coordinate(.toMain(wallet)))
		case .onboarding:
			return .none
		case let .splash(.coordinate(.loadWalletResult(loadWalletResult))):
			switch loadWalletResult {
			case let .walletLoaded(wallet):
				return Effect(value: .coordinate(.toMain(wallet)))
			case let .noWallet(reason):
				state = App.State.alert(.init(
					title: TextState(reason),
					buttons: [
						.cancel(
							TextState("OK, I'll onboard"),
							action: .send(.coordinate(.onboard))
						),
					]
				))
				return .none
			}
		case .splash:
			return .none
		case .coordinate(.onboard):
			state = .onboarding(.init())
			return .none
		case let .coordinate(.toMain(wallet)):
			// FIXME: wallet
//			state = .main(.init(wallet: wallet))
			state = .main(.placeholder)
			return .none
		case .internal(.user(.alertDismissed)):
			state = .alert(nil)
			return .none
		}
	}
}
