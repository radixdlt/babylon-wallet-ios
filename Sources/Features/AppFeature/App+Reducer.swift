import ComposableArchitecture
import MainFeature
import OnboardingFeature
import ProfileClient
import SplashFeature

public struct App: ReducerProtocol {
	public init() {}

	@Dependency(\.profileClient) var profileClient

	public var body: some ReducerProtocol<State, Action> {
		Reduce { state, action in
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
				return .run { [profileClient] send in
					await send(.internal(.system(.injectProfileIntoProfileClientResult(
						TaskResult {
							try await profileClient.injectProfile(profile, persistIntoKeychain ? InjectProfileMode.injectAndPersistInKeychain : InjectProfileMode.onlyInject)
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
		.ifCaseLet(/App.State.main, action: /Action.child .. Action.ChildAction.main) {
			Main()
		}
		.ifCaseLet(/App.State.onboarding, action: /Action.child .. Action.ChildAction.onboarding) {
			Onboarding()
		}
		.ifCaseLet(/App.State.splash, action: /Action.child .. Action.ChildAction.splash) {
			Splash()
		}
	}
}
