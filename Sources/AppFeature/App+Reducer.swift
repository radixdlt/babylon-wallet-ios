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
						accountPortfolioFetcher: $0.accountPortfolioFetcher,
						appSettingsClient: $0.appSettingsClient,
						keychainClient: $0.keychainClient,
						pasteboardClient: $0.pasteboardClient,
						walletClient: $0.walletClient
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
						profileLoader: $0.profileLoader
					)
				}
			),

		appReducer
	)
	// .debug()

	static let appReducer = Reducer { state, action, environment in
		switch action {
		case .main(.coordinate(.removedWallet)):
			state = .onboarding(.init())
			return Effect(value: .coordinate(.onboard))

		case let .onboarding(.coordinate(.onboardedWithProfile(profile))):
			return .run { send in
				await send(.internal(.injectProfileIntoWalletClient(profile)))
			}

		case let .splash(.coordinate(.loadProfileResult(.profileLoaded(profile)))):
			return .run { send in
				await send(.internal(.injectProfileIntoWalletClient(profile)))
			}
		case let .splash(.coordinate(.loadProfileResult(.noProfile(reason, failedToDecode)))):
			if failedToDecode {
				print("Fix this, failed to load wallet: \(reason)")
				return .none
			} else {
				return .run { send in
					await send(.coordinate(.onboard))
				}
			}

		case let .internal(.injectProfileIntoWalletClient(profile)):
			return .run { send in
				environment.walletClient.injectProfile(profile)
				await send(.coordinate(.toMain))
			}

		case .coordinate(.onboard):
			state = .onboarding(.init())
			return .none

		case .coordinate(.toMain):
			state = .main(.init())
			return .none

		case .main:
			return .none

		case .onboarding:
			return .none

		case .splash:
			return .none
		}
	}
}
