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
	@Dependency(\.keychainClient) var keychainClient
	@Dependency(\.profileClient) var profileClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
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

		case let .child(.onboarding(.createAccount(.delegate(.createdNewProfile(newProfile))))):
			return injectProfileIntoProfileClient(newProfile)

		case let .child(.splash(.delegate(.profileResultLoaded(profileResult)))):
			switch profileResult {
			case let .decodingFailure(_, error):
				errorQueue.schedule(error)
				goToOnboarding(state: &state)
				return .none
			case let .failedToCreateProfileFromSnapshot(failedToCreateProfileFromSnapshot):
				return incompatibleSnapshotData(version: failedToCreateProfileFromSnapshot.version, state: &state)
			case .noProfile:
				goToOnboarding(state: &state)
				return .none
			case let .profileVersionOutdated(_, version):
				return incompatibleSnapshotData(version: version, state: &state)
			case let .compatibleProfile(profile):
				return injectProfileIntoProfileClient(profile)
			}

		case .internal(.system(.injectProfileIntoProfileClientResult(.success(_)))):
			goToMain(state: &state)
			return .none

		case let .internal(.system(.injectProfileIntoProfileClientResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case .internal(.view(.deleteIncompatibleProfile)):
			return .run { send in
				do {
					try await keychainClient.removeProfileSnapshot()
				} catch {
					await errorQueue.schedule(error)
				}
				await send(.internal(.system(.deletedIncompatibleProfile)))
			}
		case .internal(.system(.deletedIncompatibleProfile)):
			goToOnboarding(state: &state)
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

	func incompatibleSnapshotData(version: ProfileSnapshot.Version, state: inout State) -> EffectTask<Action> {
		state.errorAlert = .init(
			title: .init("Incompatible Profile found"),
			message: .init("Saved Profile has version: \(String(describing: version)), but this app requires a minimum Profile version of \(String(describing: ProfileSnapshot.Version.minimum)). You must delete the Profile and create a new one to use this app."),
			dismissButton: .destructive(.init("Delete"), action: .send(Action.ViewAction.deleteIncompatibleProfile))
		)
		return .none
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
