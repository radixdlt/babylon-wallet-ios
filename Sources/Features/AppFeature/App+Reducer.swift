import ComposableArchitecture
import ErrorQueue
import Foundation
import MainFeature
import OnboardingFeature
import ProfileClient
import SplashFeature

// MARK: - App
public struct App: ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.profileClient) var profileClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.root, action: /Action.self) {
			EmptyReducer()
				.ifCaseLet(/App.State.Root.main, action: /Action.child .. Action.ChildAction.main) {
					Main()
					// ._printChanges()
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
			return .run { [errorQueue] send in
				for try await error in errorQueue.errors() {
					await send(.internal(.system(.displayErrorAlert(UserFacingError(error)))))
				}
			}

		case let .internal(.system(.displayErrorAlert(error))):
			state.errorAlert = .init(
				title: .init("An error ocurred"),
				message: .init(error.legibleLocalizedDescription)
			)
			return .none

		case .internal(.view(.errorAlertDismissButtonTapped)):
			state.errorAlert = nil
			return .none

		case .child(.main(.delegate(.removedWallet))):
			goToOnboarding(state: &state)
			return .none

		case let .child(.onboarding(.child(.newProfile(.delegate(.finishedCreatingNewProfile(newProfile)))))):
			return injectProfileIntoProfileClient(newProfile)

		case let .child(.onboarding(.child(.importMnemonic(.delegate(.finishedImporting(_, profile)))))):
			return injectProfileIntoProfileClient(profile)

		case let .child(.splash(.delegate(.profileLoaded(profile)))):
			if let profile {
				return injectProfileIntoProfileClient(profile)
			} else {
				goToOnboarding(state: &state)
				return .none
			}

		case .internal(.system(.injectProfileIntoProfileClientResult(.success(_)))):
			goToMain(state: &state)
			return .none

		case let .internal(.system(.injectProfileIntoProfileClientResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case .child:
			return .none
		}
	}

	func injectProfileIntoProfileClient(_ profile: Profile) -> EffectTask<Action> {
		.run { send in
			await send(.internal(.system(.injectProfileIntoProfileClientResult(
				TaskResult {
					try await profileClient.injectProfile(profile)
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

// MARK: App.UserFacingError
public extension App {
	/// A purely user-facing error. Not made for developer logging or analytics collection.
	struct UserFacingError: Equatable, LocalizedError {
		let underlyingError: Error

		init(_ underlyingError: Error) {
			self.underlyingError = underlyingError
		}

		public var errorDescription: String? {
			underlyingError.localizedDescription
		}

		public static func == (lhs: Self, rhs: Self) -> Bool {
			lhs.underlyingError.localizedDescription == rhs.underlyingError.localizedDescription
		}
	}
}
