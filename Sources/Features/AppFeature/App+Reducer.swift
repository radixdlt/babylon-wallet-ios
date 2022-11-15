import ComposableArchitecture
import ErrorQueue
import Foundation
import MainFeature
import OnboardingFeature
import ProfileClient
import SplashFeature

public struct App: ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.profileClient) var profileClient

	public init() {}

	public var body: some ReducerProtocol<State, Action> {
		Scope(state: \.root, action: /Action.self) {
			EmptyReducer()
				.ifCaseLet(/App.State.Root.main, action: /Action.child .. Action.ChildAction.main) {
					Main()
				}
				.ifCaseLet(/App.State.Root.onboarding, action: /Action.child .. Action.ChildAction.onboarding) {
					Onboarding()
				}
				.ifCaseLet(/App.State.Root.splash, action: /Action.child .. Action.ChildAction.splash) {
					Splash()
				}
		}

		Reduce(self.core)
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.task)):
			return .run { send in
				for await error in errorQueue.errors() {
					await send(.internal(.system(.displayErrorAlert(error as NSError))))
				}
			}

		case let .internal(.system(.displayErrorAlert(error))):
			state.errorAlert = .init(
				title: .init("An error ocurred"),
				message: .init(error.localizedDescription)
			)
			return .none

		case .internal(.view(.errorAlertDismissed)):
			state.errorAlert = nil
			return .none

		case .child(.main(.delegate(.removedWallet))):
			goToOnboarding(state: &state)
			return .none

		case let .child(.onboarding(.child(.newProfile(.delegate(.finishedCreatingNewProfile(newProfile)))))):
			return injectProfileIntoProfileClient(newProfile, persistIntoKeychain: true)

		case let .child(.onboarding(.child(.importMnemonic(.delegate(.finishedImporting(_, profile)))))):
			return injectProfileIntoProfileClient(profile, persistIntoKeychain: false)

		case let .child(.splash(.delegate(.loadProfileResult(.profileLoaded(profile))))):
			return injectProfileIntoProfileClient(profile, persistIntoKeychain: false)

		case let .child(.splash(.delegate(.loadProfileResult(.noProfile(reason, failedToDecode))))):
			if failedToDecode {
				struct FailedToDecodeError: LocalizedError {
					let reason: String
					var errorDescription: String? { "Failed to decode profile: \(reason)" }
				}
				errorQueue.schedule(FailedToDecodeError(reason: reason))
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
		state.root = .main(.init())
	}

	func goToOnboarding(state: inout State) {
		state.root = .onboarding(.init())
	}
}
