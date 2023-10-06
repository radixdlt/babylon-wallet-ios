import AppPreferencesClient
import FeaturePrelude
import MainFeature
import OnboardingClient
import OnboardingFeature
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

		public init(
			root: Root = .splash(.init())
		) {
			self.root = root
			loggerGlobal.info("App started")
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case alert(PresentationAction<Alerts.Action>)
	}

	public enum InternalAction: Sendable, Equatable {
		case incompatibleProfileDeleted
		case presentUsedOnOtherDeviceWarning(otherDevice: ProfileSnapshot.Header.UsedDeviceInfo)
		case toMain(isAccountRecoveryNeeded: Bool)
		case toOnboarding

		case reclaimedProfileOnThisDevice(TaskResult<Prelude.Unit>)
		case stoppedUsingProfileOnThisDevice(TaskResult<Prelude.Unit>)
	}

	public enum ChildAction: Sendable, Equatable {
		case main(Main.Action)
		case onboardingCoordinator(OnboardingCoordinator.Action)
		case splash(Splash.Action)
	}

	public struct Alerts: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case profileUsedOnOtherDeviceErrorAlert(AlertState<Action.ProfileUsedOnOtherDeviceErrorAlertAction>)
			case incompatibleProfileErrorAlert(AlertState<Action.IncompatibleProfileErrorAlertAction>)
		}

		public enum Action: Sendable, Equatable {
			case incompatibleProfileErrorAlert(IncompatibleProfileErrorAlertAction)
			case profileUsedOnOtherDeviceErrorAlert(ProfileUsedOnOtherDeviceErrorAlertAction)

			public enum ProfileUsedOnOtherDeviceErrorAlertAction: Sendable, Hashable {
				case reclaim
				case deleteProfileOnThisDevice
			}

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
	@Dependency(\.backupsClient) var backupsClient

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
			let retBuildInfo = buildInformation()
			loggerGlobal.info("EngineToolkit commit hash: \(retBuildInfo.version)")
			return .run { send in
				for try await error in errorQueue.errors() {
					guard !Task.isCancelled else { return }
					// Maybe instead we should listen here for the Profile.State change,
					// and when it switches to `.ephemeral` we navigate to onboarding.
					// For now, we react to the specific error, since the Profile.State is meant to be private.
					if let usedOnOtherDeviceError = error as? Profile.UsedOnAnotherDeviceError {
						await send(.internal(.presentUsedOnOtherDeviceWarning(otherDevice: usedOnOtherDeviceError.lastUsedOnDevice)))
						// A slight delay to allow any modal that may be shown to be dismissed.
						try? await clock.sleep(for: .seconds(0.5))
					}
				}
			}

		case .alert(.presented(.profileUsedOnOtherDeviceErrorAlert(.reclaim))):
			return .run { send in
				let result = await TaskResult {
					try await backupsClient.reclaimProfileOnThisDevice()
					return Prelude.Unit.instance
				}
				await send(.internal(.reclaimedProfileOnThisDevice(result)))
			}

		case .alert(.presented(.profileUsedOnOtherDeviceErrorAlert(.deleteProfileOnThisDevice))):
			return .run { send in
				let result = await TaskResult {
					try await backupsClient.stopUsingProfileOnThisDevice()
					return Prelude.Unit.instance
				}
				await send(.internal(.stoppedUsingProfileOnThisDevice(result)))
			}

		case .alert(.presented(.incompatibleProfileErrorAlert(.deleteWalletDataButtonTapped))):
			return .run { send in
				do {
					try await appPreferencesClient.deleteProfileAndFactorSources(true)
				} catch {
					errorQueue.schedule(error)
				}
				await send(.internal(.incompatibleProfileDeleted))
			}
		case .alert:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .stoppedUsingProfileOnThisDevice(.success):
			state.alert = nil
			return goToOnboarding(state: &state)

		case let .stoppedUsingProfileOnThisDevice(.failure(error)):
			state.alert = nil
			errorQueue.schedule(FailedToStopUsingProfileOnThisDevice(underlyingError: error))
			return .none

		case .reclaimedProfileOnThisDevice(.success):
			state.alert = nil
			return .none

		case let .reclaimedProfileOnThisDevice(.failure(error)):
			state.alert = nil
			errorQueue.schedule(FailedToReclaimProfileOnThisDevice(underlyingError: error))
			return .none

		case let .presentUsedOnOtherDeviceWarning(otherDevice):
			return profileUsed(on: otherDevice, state: &state)

		case .incompatibleProfileDeleted:
			return goToOnboarding(state: &state)

		case let .toMain(isAccountRecoveryNeeded):
			return goToMain(state: &state, accountRecoveryIsNeeded: isAccountRecoveryNeeded)

		case .toOnboarding:
			return goToOnboarding(state: &state)
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

	func profileUsed(
		on otherDevice: ProfileSnapshot.Header.UsedDeviceInfo,
		state: inout State
	) -> Effect<Action> {
		state.alert = .profileUsedOnOtherDeviceErrorAlert(
			.init(
				title: { TextState("Use the wallet data on single device only.") }, // FIXME: Strings
				actions: {
					ButtonState(role: .cancel, action: .reclaim) {
						TextState("I am only using the wallet data on this device")
					}
					ButtonState(role: .destructive, action: .deleteProfileOnThisDevice) {
						TextState("I have backed up my seed phrase and will stop using on the wallet data on this device and continue on another device.")
					}
				},
				message: { TextState("The Radix wallet app is not intended to be used with the same wallet data on multiple device. Ensure that you are not doing that.") }
			)
		)
		return .none
	}

	func goToMain(state: inout State, accountRecoveryIsNeeded: Bool) -> Effect<Action> {
		state.root = .main(.init(home: .init(accountRecoveryIsNeeded: accountRecoveryIsNeeded)))
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

// MARK: - FailedToStopUsingProfileOnThisDevice
struct FailedToStopUsingProfileOnThisDevice: LocalizedError {
	let underlyingError: String
	init(underlyingError: Error) {
		self.underlyingError = String(describing: underlyingError)
	}

	var errorDescription: String? {
		var description = "Failed to stop using wallet data on this device. Ensure you have backed up your seed phrase and the wallet backup data, then try deleting the wallet from backups in settings or re-install the app"
		#if DEBUG
		description += "\n[DEBUG ONLY]: underlying error: \(underlyingError)"
		#endif
		return description
	}
}

// MARK: - FailedToReclaimProfileOnThisDevice
struct FailedToReclaimProfileOnThisDevice: LocalizedError {
	let underlyingError: String
	init(underlyingError: Error) {
		self.underlyingError = String(describing: underlyingError)
	}

	var errorDescription: String? {
		var description = "Failed to reclaim wallet data on this device. Ensure you have backed up your seed phrase and the wallet backup data, then try deleting the wallet from backups in settings or re-install the app"
		#if DEBUG
		description += "\n[DEBUG ONLY]: underlying error: \(underlyingError)"
		#endif
		return description
	}
}
