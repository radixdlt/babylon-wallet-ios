import ComposableArchitecture
import ErrorQueue
import Foundation
import MainFeature
import OnboardingFeature
import ProfileClient
import Resources
import SplashFeature

// MARK: - App
public struct App: Sendable, ReducerProtocol {
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
					print("An error occurred", String(describing: error))
					await send(.internal(.system(.displayErrorAlert(UserFacingError(error)))))
				}
			}

		case let .internal(.system(.displayErrorAlert(error))):
			state.errorAlert = .init(
				title: .init("An error occurred"),
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
			return injectProfileIntoProfileClient(newProfile, createdNewProfile: true)

		case .child(.onboarding(.createAccount(.child(.accountCompletion(.delegate(.displayHome)))))):
			goToMain(state: &state)
			return .none

		case let .child(.splash(.delegate(.profileResultLoaded(profileResult)))):
			switch profileResult {
			case let .success(.some(profile)):
				return injectProfileIntoProfileClient(profile, createdNewProfile: false)
			case .success(.none):
				goToOnboarding(state: &state)
				return .none

			case let .failure(.decodingFailure(_, error)):
				errorQueue.schedule(error)
				goToOnboarding(state: &state)
				return .none
			case let .failure(.failedToCreateProfileFromSnapshot(failedToCreateProfileFromSnapshot)):
				return incompatibleSnapshotData(version: failedToCreateProfileFromSnapshot.version, state: &state)
			case let .failure(.profileVersionOutdated(_, version)):
				return incompatibleSnapshotData(version: version, state: &state)
			}

		case let .internal(.system(.injectProfileIntoProfileClientResult(.success(_), createdNewProfile: createdNewProfile))):
			if createdNewProfile {
				return .run { send in
					let accounts = try await profileClient.getAccounts()
					await send(.child(.onboarding(.createAccount(.delegate(.displayCreateAccountCompletion(accounts.first, isFirstAccount: true, destination: .home))))))
				}
			} else {
				goToMain(state: &state)
				return .none
			}

		case let .internal(.system(.injectProfileIntoProfileClientResult(.failure(error), createdNewProfile: _))):
			errorQueue.schedule(error)
			return .none

		case .internal(.view(.deleteIncompatibleProfile)):
			return .run { send in
				do {
					try await keychainClient.removeProfileSnapshot()
				} catch {
					errorQueue.schedule(error)
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

	func injectProfileIntoProfileClient(_ profile: Profile, createdNewProfile: Bool) -> EffectTask<Action> {
		.run { send in
			await send(.internal(.system(.injectProfileIntoProfileClientResult(
				TaskResult {
					try await profileClient.injectProfile(profile)
					return profile
				},
				createdNewProfile: createdNewProfile
			))))
		}
	}

	func incompatibleSnapshotData(version: ProfileSnapshot.Version, state: inout State) -> EffectTask<Action> {
		state.errorAlert = .init(
			title: .init(L10n.Splash.incompatibleProfileVersionAlertTitle),
			message: .init(L10n.Splash.incompatibleProfileVersionAlertMessage(String(describing: version), String(describing: ProfileSnapshot.Version.minimum))),
			dismissButton: .destructive(
				.init(L10n.Splash.incompatibleProfileVersionAlertDeleteButton),
				action: .send(Action.ViewAction.deleteIncompatibleProfile)
			)
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
	struct UserFacingError: Sendable, Equatable, LocalizedError {
		let underlyingError: Swift.Error

		init(_ underlyingError: Swift.Error) {
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
