import ComposableArchitecture
import SwiftUI

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

		public init(
			root: Root = .splash(.init())
		) {
			self.root = root
			let retBuildInfo = buildInformation()
			loggerGlobal.info("App started - engineToolkit commit hash: \(retBuildInfo.version)")
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case alert(PresentationAction<Alerts.Action>)
	}

	public enum InternalAction: Sendable, Equatable {
		case incompatibleProfileDeleted
		case toMain(isAccountRecoveryNeeded: Bool)
		case toOnboarding
	}

	public enum ChildAction: Sendable, Equatable {
		case main(Main.Action)
		case onboardingCoordinator(OnboardingCoordinator.Action)
		case splash(Splash.Action)
	}

	public struct Alerts: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case incompatibleProfileErrorAlert(AlertState<Action.IncompatibleProfileErrorAlertAction>)
		}

		public enum Action: Sendable, Equatable {
			case incompatibleProfileErrorAlert(IncompatibleProfileErrorAlertAction)

			public enum IncompatibleProfileErrorAlertAction: Sendable, Hashable {
				case deleteWalletDataButtonTapped
			}
		}

		public var body: some ReducerOf<Self> {
			EmptyReducer()
		}
	}

	@Dependency(\.continuousClock) var clock
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.appPreferencesClient) var appPreferencesClient

	public init() {}

	public var body: some ReducerOf<Self> {
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

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			.run { send in
				for try await error in errorQueue.errors() {
					guard !Task.isCancelled else { return }
					// Maybe instead we should listen here for the Profile.State change,
					// and when it switches to `.ephemeral` we navigate to onboarding.
					// For now, we react to the specific error, since the Profile.State is meant to be private.
					if error is Profile.ProfileIsUsedOnAnotherDeviceError {
						await send(.internal(.toOnboarding))
						// A slight delay to allow any modal that may be shown to be dismissed.
						try? await clock.sleep(for: .seconds(0.5))
					}
				}
			}

		case .alert(.presented(.incompatibleProfileErrorAlert(.deleteWalletDataButtonTapped))):
			.run { send in
				do {
					try await appPreferencesClient.deleteProfileAndFactorSources(true)
				} catch {
					errorQueue.schedule(error)
				}
				await send(.internal(.incompatibleProfileDeleted))
			}
		case .alert:
			.none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .incompatibleProfileDeleted:
			goToOnboarding(state: &state)

		case let .toMain(isAccountRecoveryNeeded):
			goToMain(state: &state, accountRecoveryIsNeeded: isAccountRecoveryNeeded)

		case .toOnboarding:
			goToOnboarding(state: &state)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .main(.delegate(.removedWallet)):
			return goToOnboarding(state: &state)

		case let .onboardingCoordinator(.delegate(.completed(accountRecoveryIsNeeded))):
			return goToMain(state: &state, accountRecoveryIsNeeded: accountRecoveryIsNeeded)

		case let .splash(.delegate(.completed(loadProfileOutcome, accountRecoveryNeeded))):

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

			case .existingProfile:
				return goToMain(state: &state, accountRecoveryIsNeeded: accountRecoveryNeeded)

			case let .usersExistingProfileCouldNotBeLoaded(failure: .profileUsedOnAnotherDevice(error)):
				errorQueue.schedule(error)
				return goToOnboarding(state: &state)
			}

		default:
			return .none
		}
	}

	func incompatibleSnapshotData(
		version: ProfileSnapshot.Header.Version,
		state: inout State
	) -> Effect<Action> {
		state.alert = .incompatibleProfileErrorAlert(
			.init(
				title: { TextState(L10n.Splash.IncompatibleProfileVersionAlert.title) },
				actions: {
					ButtonState(role: .destructive, action: .deleteWalletDataButtonTapped) {
						TextState(L10n.Splash.IncompatibleProfileVersionAlert.delete)
					}
				},
				message: { TextState(L10n.Splash.IncompatibleProfileVersionAlert.message) }
			)
		)
		return .none
	}

	func goToMain(state: inout State, accountRecoveryIsNeeded: Bool) -> Effect<Action> {
		state.root = .main(.init(home: .init(babylonAccountRecoveryIsNeeded: accountRecoveryIsNeeded)))
		return .none
	}

	func goToOnboarding(state: inout State) -> Effect<Action> {
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
