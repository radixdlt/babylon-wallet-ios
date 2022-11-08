import ComposableArchitecture
import MainFeature
import OnboardingFeature
import ProfileClient
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
						profileClient: $0.profileClient
					)
				}
			),
		// TODO: remove AnyReducer when migration to ReducerProtocol is complete
		AnyReducer { _ in
			Scope(state: /App.State.onboarding, action: /Action.onboarding) {
				Onboarding()
			}
		},

		Splash.reducer
			.optional()
			.pullback(
				state: /App.State.splash,
				action: /Action.splash,
				environment: {
					Splash.Environment(
						mainQueue: $0.mainQueue,
						profileLoader: $0.profileLoader
					)
				}
			),

		appReducer
	)
//	.debug()

	static let appReducer = Reducer { state, action, environment in
		switch action {
		case .main(.coordinate(.removedWallet)):
			return .run { send in
				await send(.coordinate(.onboard))
			}

		case let .onboarding(.coordinate(.onboardedWithProfile(profile, isNew))):
			return .run { send in
				await send(.internal(.injectProfileIntoProfileClient(profile, persistIntoKeychain: true)))
			}

		case let .onboarding(.coordinate(.failedToCreateOrImportProfile(failureReason))):
			return .run { send in
				await send(.coordinate(.failedToCreateOrImportProfile(reason: failureReason)))
			}

		case let .splash(.coordinate(.loadProfileResult(.profileLoaded(profile)))):
			return .run { send in
				await send(.internal(.injectProfileIntoProfileClient(profile, persistIntoKeychain: false)))
			}

		case let .splash(.coordinate(.loadProfileResult(.noProfile(reason, failedToDecode)))):
			if failedToDecode {
				return .run { send in
					await send(.coordinate(.failedToCreateOrImportProfile(reason: "Failed to decode profile: \(reason)")))
				}
			} else {
				return .run { send in
					await send(.coordinate(.onboard))
				}
			}

		case let .internal(.injectProfileIntoProfileClient(profile, persistIntoKeychain)):
			return .run { send in
				await send(.internal(.injectProfileIntoProfileClientResult(
					TaskResult {
						try await environment.profileClient.injectProfile(profile, persistIntoKeychain ? InjectProfileMode.injectAndPersistInKeychain : InjectProfileMode.onlyInject)
						return profile
					}
				)))
			}
		case let .internal(.injectProfileIntoProfileClientResult(.success(profile))):
			return .run { send in
				await send(.coordinate(.toMain))
			}
		case let .internal(.injectProfileIntoProfileClientResult(.failure(error))):
			fatalError(String(describing: error))

		case .coordinate(.onboard):
			state = .onboarding(.init())
			return .none

		case .coordinate(.toMain):
			state = .main(.init())
			return .none

		case let .coordinate(.failedToCreateOrImportProfile(reason)):
			// FIXME: display error to user...
			print("ERROR: \(reason)")
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
