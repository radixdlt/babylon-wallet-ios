import ComposableArchitecture
import MainFeature
import OnboardingFeature
import SplashFeature

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
						accountWorthFetcher: $0.accountWorthFetcher,
						appSettingsClient: $0.appSettingsClient,
						pasteboardClient: $0.pasteboardClient,
						walletRemover: $0.walletRemover
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
			return Effect(value: .coordinate(.toMain(wallet)))
		case .onboarding:
			return .none
		case let .splash(.coordinate(.loadWalletResult(loadWalletResult))):
			switch loadWalletResult {
			case let .walletLoaded(wallet):
				return Effect(value: .coordinate(.toMain(wallet)))
			case let .noWallet(reason, failedToDecode):
				if failedToDecode {
					print("Fix this, failed to load wallet: \(reason)")
					return .none
				} else {
					return .run { send in
						await send(.coordinate(.onboard))
					}
				}
			}
		case .splash:
			return .none
		case .coordinate(.onboard):
			state = .onboarding(.init())
			return .none
		case let .coordinate(.toMain(wallet)):
			state = .main(.init(home: .init(justA: wallet)))
			return .none
		}
	}
}
