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
				action: /Action.child .. Action.ChildAction.main,
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
			Scope(state: /App.State.onboarding, action: /Action.child .. Action.ChildAction.onboarding) {
				Onboarding()
			}
		},

		Splash.reducer
			.optional()
			.pullback(
				state: /App.State.splash,
				action: /Action.child .. Action.ChildAction.splash,
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
		case .child(.main(.delegate(.removedWallet))):
			return .run { send in
				await send(.internal(.system(.goToOnboarding)))
			}

		case let .child(.onboarding(.delegate(.onboardedWithProfile(profile, isNew)))):
			return .run { send in
				await send(.internal(.system(.injectProfileIntoProfileClient(profile, persistIntoKeychain: true))))
			}

		case let .child(.onboarding(.delegate(.failedToCreateOrImportProfile(failureReason)))):
			return .run { send in
				await send(.internal(.system(.failedToCreateOrImportProfile(reason: failureReason))))
			}

		case let .child(.splash(.delegate(.loadProfileResult(.profileLoaded(profile))))):
			return .run { send in
				await send(.internal(.system(.injectProfileIntoProfileClient(profile, persistIntoKeychain: false))))
			}

		case let .child(.splash(.delegate(.loadProfileResult(.noProfile(reason, failedToDecode))))):
			if failedToDecode {
				return .run { send in
					await send(.internal(.system(.failedToCreateOrImportProfile(reason: "Failed to decode profile: \(reason)"))))
				}
			} else {
				return .run { send in
					await send(.internal(.system(.goToOnboarding)))
				}
			}

		// TODO: refactor into func after converting to reducer protocol
		case let .internal(.system(.injectProfileIntoProfileClient(profile, persistIntoKeychain))):
			return .run { send in
				await send(.internal(.system(.injectProfileIntoProfileClientResult(
					TaskResult {
						try await environment.profileClient.injectProfile(profile, persistIntoKeychain ? InjectProfileMode.injectAndPersistInKeychain : InjectProfileMode.onlyInject)
						return profile
					}
				))))
			}

		case let .internal(.system(.injectProfileIntoProfileClientResult(.success(profile)))):
			return .run { send in
				await send(.internal(.system(.goToMain)))
			}

		case let .internal(.system(.injectProfileIntoProfileClientResult(.failure(error)))):
			fatalError(String(describing: error))

		case .internal(.system(.goToOnboarding)):
			state = .onboarding(.init())
			return .none

		case .internal(.system(.goToMain)):
			state = .main(.init())
			return .none

		case let .internal(.system(.failedToCreateOrImportProfile(reason))):
			// FIXME: display error to user...
			print("ERROR: \(reason)")
			return .none

		case .child:
			return .none
		}
	}
}
