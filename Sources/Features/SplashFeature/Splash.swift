import DeviceFactorSourceClient
import FeaturePrelude
import GatewayAPI
import LocalAuthenticationClient
import NetworkSwitchingClient
import OnboardingClient

// MARK: - Splash
public struct Splash: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		public var passcodeCheckFailedAlert: AlertState<ViewAction.PasscodeCheckFailedAlertAction>?

		var biometricsCheckFailed: Bool = false

		public init(
			passcodeCheckFailedAlert: AlertState<ViewAction.PasscodeCheckFailedAlertAction>? = nil
		) {
			self.passcodeCheckFailedAlert = passcodeCheckFailedAlert
		}
	}

	public enum ViewAction: Sendable, Equatable {
		public enum PasscodeCheckFailedAlertAction: Sendable, Equatable {
			case retryButtonTapped
			case openSettingsButtonTapped
		}

		case appeared
		case passcodeCheckFailedAlert(PresentationAction<PasscodeCheckFailedAlertAction>)
		case didTapToUnlock
	}

	public enum InternalAction: Sendable, Equatable {
		case passcodeConfigResult(TaskResult<LocalAuthenticationConfig>)
		case loadProfileOutcome(LoadProfileOutcome)
		case accountRecoveryNeeded(LoadProfileOutcome, TaskResult<Bool>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed(LoadProfileOutcome, accountRecoveryNeeded: Bool, hasMainnetEverBeenLive: Bool)
	}

	@Dependency(\.networkSwitchingClient) var networkSwitchingClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.continuousClock) var clock
	@Dependency(\.localAuthenticationClient) var localAuthenticationClient
	@Dependency(\.onboardingClient.loadProfile) var loadProfile
	@Dependency(\.openURL) var openURL
	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$passcodeCheckFailedAlert, action: /Action.view .. ViewAction.passcodeCheckFailedAlert)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return delay().concatenate(with: verifyPasscode())

		case .didTapToUnlock:
			state.biometricsCheckFailed = false
			return .run { send in
				await send(.internal(.loadProfileOutcome(loadProfile())))
			}

		case let .passcodeCheckFailedAlert(.presented(action)):
			switch action {
			case .retryButtonTapped:
				return verifyPasscode()
			case .openSettingsButtonTapped:
				#if os(iOS)
				return .run { _ in
					await openURL(URL(string: UIApplication.openSettingsURLString)!)
				}
				#else
				return .none
				#endif
			}
		case .passcodeCheckFailedAlert:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .passcodeConfigResult(result):
			let config = try? result.value

			guard config?.isPasscodeSetUp == true else {
				state.passcodeCheckFailedAlert = .init(
					title: { .init(L10n.Splash.PasscodeCheckFailedAlert.title) },
					actions: {
						ButtonState(
							role: .none,
							action: .send(.retryButtonTapped),
							label: { TextState(L10n.Common.retry) }
						)
						ButtonState(
							role: .none,
							action: .send(.openSettingsButtonTapped),
							label: { TextState(L10n.Common.systemSettings) }
						)
					},
					message: { .init(L10n.Splash.PasscodeCheckFailedAlert.message) }
				)

				return .none
			}

			return .run { send in
				await send(.internal(.loadProfileOutcome(loadProfile())))
			}

		case let .loadProfileOutcome(outcome):
			if case .existingProfile = outcome {
				return checkAccountRecoveryNeeded(outcome)
			}
			return delegateCompleted(loadProfileOutcome: outcome, accountRecoveryNeeded: false)

		case .accountRecoveryNeeded(_, .failure):
			state.biometricsCheckFailed = true
			return .none

		case let .accountRecoveryNeeded(outcome, .success(recoveryNeeded)):
			return delegateCompleted(loadProfileOutcome: outcome, accountRecoveryNeeded: recoveryNeeded)
		}
	}

	func delegateCompleted(loadProfileOutcome: LoadProfileOutcome, accountRecoveryNeeded: Bool) -> EffectTask<Action> {
		.run { send in
			let hasMainnetEverBeenLive = await networkSwitchingClient.hasMainnetEverBeenLive()
			await send(.delegate(
				.completed(
					loadProfileOutcome,
					accountRecoveryNeeded: accountRecoveryNeeded,
					hasMainnetEverBeenLive: hasMainnetEverBeenLive
				))
			)
		}
	}

	func checkAccountRecoveryNeeded(_ loadProfileOutcome: LoadProfileOutcome) -> EffectTask<Action> {
		.run { send in
			await send(.internal(.accountRecoveryNeeded(
				loadProfileOutcome,
				.init {
					try await deviceFactorSourceClient.isAccountRecoveryNeeded()
				}
			)))
		}
	}

	private func delay() -> EffectTask<Action> {
		.run { _ in
			let durationInMS: Int
			#if DEBUG
			durationInMS = 400
			#else
			durationInMS = 750
			#endif
			try? await clock.sleep(for: .milliseconds(durationInMS))
		}
	}

	private func verifyPasscode() -> EffectTask<Action> {
		.run { send in
			await send(.internal(.passcodeConfigResult(
				TaskResult {
					try await localAuthenticationClient.queryConfig()
				}
			)))
		}
	}
}
