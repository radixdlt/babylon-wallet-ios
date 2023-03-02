import FeaturePrelude
import MainFeature
import OnboardingClient
import OnboardingFeature
import SecureStorageClient
import SplashFeature

// MARK: - App
public struct App: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.secureStorageClient) var secureStorageClient
	// FIXME: this is temporary and will be reworked during multifactor work.
	@Dependency(\.onboardingClient.loadEphemeralPrivateProfile) var loadEphemeralPrivateProfile

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.root, action: /Action.child) {
			EmptyReducer()
				.ifCaseLet(/State.Root.main, action: /Action.ChildAction.main) {
					Main()
				}
				.ifCaseLet(/State.Root.onboardingCoordinator, action: /Action.ChildAction.onboardingCoordinator) {
					OnboardingCoordinator()
				}
				.ifCaseLet(/State.Root.splash, action: /Action.ChildAction.splash) {
					Splash()
				}
		}

		Reduce(self.core)
			.presentationDestination(\.$alert, action: /Action.internal .. Action.InternalAction.view .. Action.ViewAction.alert) {
				Alerts()
			}
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.task)):
			return .run { send in
				for try await error in errorQueue.errors() {
					if !_XCTIsTesting {
						// easy to think a test failed if we print this warning during tests.
						loggerGlobal.error("An error occurred: \(String(describing: error))")
					}
					await send(.internal(.system(.displayErrorAlert(UserFacingError(error)))))
				}
			}

		case let .internal(.system(.displayErrorAlert(error))):
			state.alert = .userErrorAlert(
				.init(
					title: { TextState(L10n.App.errorOccurredTitle) },
					actions: {},
					message: { TextState(error.legibleLocalizedDescription) }
				)
			)
			return .none

		case .child(.main(.delegate(.removedWallet))):
			return goToOnboarding(state: &state)

		case .child(.onboardingCoordinator(.delegate(.completed))):
			return goToMain(state: &state)

		case let .child(.splash(.delegate(.loadProfileOutcome(loadProfileOutcome)))):
			switch loadProfileOutcome {
			case .newUser:
				return goToOnboarding(state: &state)

			case let .usersExistingProfileCouldNotBeLoaded(.decodingFailure(_, error)):
				errorQueue.schedule(error)
				return goToOnboarding(state: &state)

			case let .usersExistingProfileCouldNotBeLoaded(.failedToCreateProfileFromSnapshot(failedToCreateProfileFromSnapshot)):
				return incompatibleSnapshotData(version: failedToCreateProfileFromSnapshot.version, state: &state)

			case let .usersExistingProfileCouldNotBeLoaded(.profileVersionOutdated(_, version)):
				return incompatibleSnapshotData(version: version, state: &state)

			case .existingProfileLoaded:
				return goToMain(state: &state)
			}

		case .internal(.view(.alert(.presented(.incompatibleProfileErrorAlert(.deleteWalletDataButtonTapped))))):
			return .run { send in
				do {
					try await secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs()
				} catch {
					errorQueue.schedule(error)
				}
				await send(.internal(.system(.incompatibleProfileDeleted)))
			}

		case let .internal(.system(.loadEphemeralPrivateProfileResult(.failure(error)))):
			fatalError("Unable to use app, failed to load ephemeral private profile, failure: \(String(describing: error))")

		case let .internal(.system(.loadEphemeralPrivateProfileResult(.success(ephemeralPrivateProfile)))):
			state.root = .onboardingCoordinator(.init(ephemeralPrivateProfile: ephemeralPrivateProfile))
			return .none

		case .internal(.system(.incompatibleProfileDeleted)):
			return goToOnboarding(state: &state)

		case .child, .internal(.view(.alert)):
			return .none
		}
	}

	func incompatibleSnapshotData(version: ProfileSnapshot.Version, state: inout State) -> EffectTask<Action> {
		state.alert = .incompatibleProfileErrorAlert(
			.init(
				title: { TextState(L10n.Splash.incompatibleProfileVersionAlertTitle) },
				actions: {
					ButtonState(role: .destructive, action: .deleteWalletDataButtonTapped) {
						TextState(L10n.Splash.incompatibleProfileVersionAlertDeleteButton)
					}
				},
				message: { TextState(L10n.Splash.incompatibleProfileVersionAlertMessage) }
			)
		)
		return .none
	}

	func goToMain(state: inout State) -> EffectTask<Action> {
		state.root = .main(.init())
		return .none
	}

	func goToOnboarding(state: inout State) -> EffectTask<Action> {
		.run { send in
			await send(.internal(.system(.loadEphemeralPrivateProfileResult(TaskResult {
				try await loadEphemeralPrivateProfile()
			}))))
		}
	}
}

// MARK: App.UserFacingError
extension App {
	/// A purely user-facing error. Not made for developer logging or analytics collection.
	public struct UserFacingError: Sendable, Equatable, LocalizedError {
		let underlyingError: Swift.Error

		init(_ underlyingError: Swift.Error) {
			self.underlyingError = underlyingError
		}

		public var errorDescription: String? {
			underlyingError.legibleLocalizedDescription
		}

		public static func == (lhs: Self, rhs: Self) -> Bool {
			lhs.underlyingError.localizedDescription == rhs.underlyingError.localizedDescription
		}
	}
}
