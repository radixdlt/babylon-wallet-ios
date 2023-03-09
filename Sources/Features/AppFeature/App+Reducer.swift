import FeaturePrelude
import MainFeature
import OnboardingClient
import OnboardingFeature
import SecureStorageClient
import SplashFeature

// MARK: - App
public struct App: Sendable, FeatureReducer {
	public struct State: Hashable {
		public enum Root: Hashable {
			case main(Main.State)
			case onboardingCoordinator(OnboardingCoordinator.State)
			case splash(Splash.State)
		}

		public var root: Root

		@PresentationState
		public var alert: Alerts.State?

		public init(root: Root = .splash(.init())) {
			self.root = root
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case alert(PresentationAction<Alerts.Action>)
	}

	public enum InternalAction: Sendable, Equatable {
		case incompatibleProfileDeleted
		case displayErrorAlert(App.UserFacingError)
	}

	public enum ChildAction: Sendable, Equatable {
		case main(Main.Action)
		case onboardingCoordinator(OnboardingCoordinator.Action)
		case splash(Splash.Action)
	}

	public struct Alerts: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case userErrorAlert(AlertState<Action.UserErrorAlertAction>)
			case incompatibleProfileErrorAlert(AlertState<Action.IncompatibleProfileErrorAlertAction>)
		}

		public enum Action: Sendable, Equatable {
			case userErrorAlert(UserErrorAlertAction)
			case incompatibleProfileErrorAlert(IncompatibleProfileErrorAlertAction)

			public enum UserErrorAlertAction: Sendable, Hashable {
				// NB: no actions, just letting the system show the default "OK" button
			}

			public enum IncompatibleProfileErrorAlertAction: Sendable, Hashable {
				case deleteWalletDataButtonTapped
			}
		}

		public var body: some ReducerProtocolOf<Self> {
			EmptyReducer()
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.secureStorageClient) var secureStorageClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.root, action: /Action.child) {
			EmptyReducer()
				.ifCaseLet(/State.Root.main, action: /ChildAction.main) {
					Main()
				}
				.ifCaseLet(/State.Root.onboardingCoordinator, action: /ChildAction.onboardingCoordinator) {
					OnboardingCoordinator()
				}
				.ifCaseLet(/State.Root.splash, action: /ChildAction.splash) {
					Splash()
				}
		}

		Reduce(core)
			.ifLet(\.$alert, action: /Action.view .. ViewAction.alert) {
				Alerts()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				for try await error in errorQueue.errors() {
					if !_XCTIsTesting {
						// easy to think a test failed if we print this warning during tests.
						loggerGlobal.error("An error occurred: \(String(describing: error))")
					}
					await send(.internal(.displayErrorAlert(UserFacingError(error))))
				}
			}

		case .alert(.presented(.incompatibleProfileErrorAlert(.deleteWalletDataButtonTapped))):
			return .run { send in
				do {
					try await secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs()
				} catch {
					errorQueue.schedule(error)
				}
				await send(.internal(.incompatibleProfileDeleted))
			}
		case .alert:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .displayErrorAlert(error):
			state.alert = .userErrorAlert(
				.init(
					title: { TextState(L10n.App.errorOccurredTitle) },
					actions: {},
					message: { TextState(error.legibleLocalizedDescription) }
				)
			)
			return .none

		case .incompatibleProfileDeleted:
			return goToOnboarding(state: &state)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .main(.delegate(.removedWallet)):
			return goToOnboarding(state: &state)

		case .onboardingCoordinator(.delegate(.completed)):
			return goToMain(state: &state)

		case let .splash(.delegate(.loadProfileOutcome(loadProfileOutcome))):
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

		default:
			return .none
		}
	}

	func incompatibleSnapshotData(
		version: ProfileSnapshot.Version,
		state: inout State
	) -> EffectTask<Action> {
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
		state.root = .onboardingCoordinator(.init())
		return .none
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
