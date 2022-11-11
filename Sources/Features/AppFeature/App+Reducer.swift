import ComposableArchitecture
import MainFeature
import OnboardingFeature
import ProfileClient
import SplashFeature

public struct App: ReducerProtocol {
	@Dependency(\.profileClient) var profileClient

	public init() {}

	public var body: some ReducerProtocol<State, Action> {
		EmptyReducer()
			.ifCaseLet(/App.State.main, action: /Action.child .. Action.ChildAction.main) {
				Main()
			}
			.ifCaseLet(/App.State.onboarding, action: /Action.child .. Action.ChildAction.onboarding) {
				Onboarding()
			}
			.ifCaseLet(/App.State.splash, action: /Action.child .. Action.ChildAction.splash) {
				Splash()
			}

		Reduce { state, action in
			switch action {
			case .child(.main(.delegate(.removedWallet))):
				goToOnboarding(state: &state)
				return .none

			case let .child(.onboarding(.delegate(.onboardedWithProfile(profile, isNew)))):
				return injectProfileIntoProfileClient(profile, persistIntoKeychain: isNew)

			case let .child(.onboarding(.delegate(.failedToCreateOrImportProfile(failureReason)))):
				displayError(state: &state, reason: failureReason)
				return .none

			case let .child(.splash(.delegate(.loadProfileResult(.profileLoaded(profile))))):
				return injectProfileIntoProfileClient(profile, persistIntoKeychain: false)

			case let .child(.splash(.delegate(.loadProfileResult(.noProfile(reason, failedToDecode))))):
				if failedToDecode {
					displayError(state: &state, reason: "Failed to decode profile: \(reason)")
					return .none
				} else {
					goToOnboarding(state: &state)
					return .none
				}

			case let .internal(.system(.injectProfileIntoProfileClientResult(.success(profile)))):
				goToMain(state: &state)
				return .none

			case let .internal(.system(.injectProfileIntoProfileClientResult(.failure(error)))):
				fatalError(String(describing: error))

			case .child:
				return .none
			}
		}
	}

	func displayError(state: inout State, reason: String) {
		// FIXME: display error to user...
		print("ERROR: \(reason)")
	}

	func injectProfileIntoProfileClient(_ profile: Profile, persistIntoKeychain: Bool) -> EffectTask<Action> {
		.run { send in
			await send(.internal(.system(.injectProfileIntoProfileClientResult(
				TaskResult {
					let mode = persistIntoKeychain ? InjectProfileMode.injectAndPersistInKeychain : InjectProfileMode.onlyInject
					try await profileClient.injectProfile(profile, mode)
					return profile
				}
			))))
		}
	}

	func goToMain(state: inout State) {
		state = .main(.init())
	}

	func goToOnboarding(state: inout State) {
		state = .onboarding(.init())
	}
}
