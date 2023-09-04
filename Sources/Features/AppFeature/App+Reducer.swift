import AppPreferencesClient
import CreateAccountFeature
import EngineKit
import FeaturePrelude
import GatewayAPI
import GatewaysClient
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
			case onboardTestnetUserToMainnet(CreateAccountCoordinator.State)
		}

		public var root: Root
		public var showIsUsingTestnetBanner = false

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
		case checkIfMainnetIsOnlineAndThenOnboardUser
		case incompatibleProfileDeleted
		case toMain(isAccountRecoveryNeeded: Bool)
		case toOnboarding(isMainnetOnline: Bool)
		case currentGatewayChanged(to: Radix.Gateway)
	}

	public enum ChildAction: Sendable, Equatable {
		case main(Main.Action)
		case onboardingCoordinator(OnboardingCoordinator.Action)
		case splash(Splash.Action)
		case onboardTestnetUserToMainnet(CreateAccountCoordinator.Action)
	}

	public struct Alerts: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case incompatibleProfileErrorAlert(AlertState<Action.IncompatibleProfileErrorAlertAction>)
		}

		public enum Action: Sendable, Equatable {
			case incompatibleProfileErrorAlert(IncompatibleProfileErrorAlertAction)

			public enum IncompatibleProfileErrorAlertAction: Sendable, Hashable {
				case deleteWalletDataButtonTapped
			}
		}

		public var body: some ReducerProtocolOf<Self> {
			EmptyReducer()
		}
	}

	@Dependency(\.continuousClock) var clock
	@Dependency(\.gatewayAPIClient) var gatewayAPIClient
	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.appPreferencesClient) var appPreferencesClient

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
				.ifCaseLet(/State.Root.onboardTestnetUserToMainnet, action: /ChildAction.onboardTestnetUserToMainnet) {
					CreateAccountCoordinator()
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
			let retBuildInfo = buildInformation()
			print("EngineToolkit commit hash: \(retBuildInfo.version)")
			return .merge(
				.run { send in
					for try await gateways in await gatewaysClient.gatewaysValues() {
						guard !Task.isCancelled else { return }
						loggerGlobal.critical("Changed network to: \(gateways.current)")
						await send(.internal(.currentGatewayChanged(to: gateways.current)))
					}
				},
				.run { send in
					for try await error in errorQueue.errors() {
						guard !Task.isCancelled else { return }
						// Maybe instead we should listen here for the Profile.State change,
						// and when it switches to `.ephemeral` we navigate to onboarding.
						// For now, we react to the specific error, since the Profile.State is meant to be private.
						if error is Profile.ProfileIsUsedOnAnotherDeviceError {
							await send(.internal(.checkIfMainnetIsOnlineAndThenOnboardUser))
							// A slight delay to allow any modal that may be shown to be dismissed.
							try? await clock.sleep(for: .seconds(0.5))
						}
					}
				}
			)

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

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case .incompatibleProfileDeleted:
			return checkIfMainnetIsOnlineThenGoToOnboarding()
		case let .toMain(isAccountRecoveryNeeded):
			return goToMain(state: &state, accountRecoveryIsNeeded: isAccountRecoveryNeeded)
		case .checkIfMainnetIsOnlineAndThenOnboardUser:
			return checkIfMainnetIsOnlineThenGoToOnboarding()
		case let .toOnboarding(isMainnetOnline):
			return goToOnboarding(state: &state, isMainnetLive: isMainnetOnline)
		case let .currentGatewayChanged(currentGateway):
			state.showIsUsingTestnetBanner = currentGateway.network.id != .mainnet
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .main(.delegate(.removedWallet)):
			return checkIfMainnetIsOnlineThenGoToOnboarding()

		case let .onboardTestnetUserToMainnet(.delegate(onboardTestnetUserToMainnetDelegate)):
			switch onboardTestnetUserToMainnetDelegate {
			case .completed:
				// We should have switched to mainnet already, part of onboarding
				return .send(.internal(.toMain(isAccountRecoveryNeeded: false)))

			case .dismissed:
				assertionFailure("Expected to have created account on mainnet, but the create account flow got dismissed, it should NOT be dismissable.")
				return goToMain(state: &state, accountRecoveryIsNeeded: false)
			}

		case let .onboardingCoordinator(.delegate(.completed(accountRecoveryIsNeeded, hasMainnetAccounts, isMainnetLive))):
			return onboardUserToMainnetIfNeededElseGoToMain(
				hasMainnetAccounts: hasMainnetAccounts,
				isMainnetLive: isMainnetLive,
				accountRecoveryIsNeeded: accountRecoveryIsNeeded,
				state: &state
			)

		case let .splash(.delegate(.completed(loadProfileOutcome, accountRecoveryNeeded, isMainnetLive))):
			switch loadProfileOutcome {
			case .newUser:
				return goToOnboarding(state: &state, isMainnetLive: isMainnetLive)

			case let .usersExistingProfileCouldNotBeLoaded(.decodingFailure(_, error)):
				errorQueue.schedule(error)
				return goToOnboarding(state: &state, isMainnetLive: isMainnetLive)

			case let .usersExistingProfileCouldNotBeLoaded(.failedToCreateProfileFromSnapshot(failedToCreateProfileFromSnapshot)):
				return incompatibleSnapshotData(version: failedToCreateProfileFromSnapshot.version, state: &state)

			case let .usersExistingProfileCouldNotBeLoaded(.profileVersionOutdated(_, version)):
				return incompatibleSnapshotData(version: version, state: &state)

			case let .existingProfile(hasMainnetAccounts):
				return onboardUserToMainnetIfNeededElseGoToMain(
					hasMainnetAccounts: hasMainnetAccounts,
					isMainnetLive: isMainnetLive,
					accountRecoveryIsNeeded: accountRecoveryNeeded,
					state: &state
				)

			case let .usersExistingProfileCouldNotBeLoaded(failure: .profileUsedOnAnotherDevice(error)):
				errorQueue.schedule(error)
				return goToOnboarding(state: &state, isMainnetLive: isMainnetLive)
			}

		default:
			return .none
		}
	}

	func onboardUserToMainnetIfNeededElseGoToMain(
		hasMainnetAccounts: Bool,
		isMainnetLive: Bool,
		accountRecoveryIsNeeded: Bool,
		state: inout State
	) -> EffectTask<Action> {
		if !hasMainnetAccounts, isMainnetLive {
			loggerGlobal.feature("mainnet is live, but has no accounts => onboarding existing user to mainnet")
			return onboardUserToMainnet(state: &state)
		} else {
			return goToMain(state: &state, accountRecoveryIsNeeded: accountRecoveryIsNeeded)
		}
	}

	func checkIfMainnetIsOnlineThenGoToOnboarding() -> EffectTask<Action> {
		.run { send in
			let isMainnetOnline = await gatewayAPIClient.isMainnetOnline()
			await send(.internal(.toOnboarding(isMainnetOnline: isMainnetOnline)))
		}
	}

	func onboardUserToMainnet(state: inout State) -> EffectTask<Action> {
		state.root = .onboardTestnetUserToMainnet(.init(config: .init(purpose: .firstAccountOnNewNetwork(.mainnet))))
		return .none
	}

	func incompatibleSnapshotData(
		version: ProfileSnapshot.Header.Version,
		state: inout State
	) -> EffectTask<Action> {
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

	func goToMain(state: inout State, accountRecoveryIsNeeded: Bool) -> EffectTask<Action> {
		state.root = .main(.init(home: .init(accountRecoveryIsNeeded: accountRecoveryIsNeeded)))
		return .none
	}

	func goToOnboarding(state: inout State, isMainnetLive: Bool) -> EffectTask<Action> {
		state.root = .onboardingCoordinator(.init(isMainnetLive: isMainnetLive))
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
