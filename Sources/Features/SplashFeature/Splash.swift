import FeaturePrelude
import LocalAuthenticationClient
import OnboardingClient

// MARK: - Splash
public struct Splash: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		public var passcodeCheckFailedAlert: AlertState<ViewAction.PasscodeCheckFailedAlertAction>?

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
	}

	public enum InternalAction: Sendable, Equatable {
		case passcodeConfigResult(TaskResult<LocalAuthenticationConfig>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case loadProfileOutcome(LoadProfileOutcome)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.continuousClock) var clock
	@Dependency(\.localAuthenticationClient) var localAuthenticationClient
	@Dependency(\.onboardingClient.loadProfile) var loadProfile
	@Dependency(\.openURL) var openURL

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$passcodeCheckFailedAlert, action: /Action.view .. ViewAction.passcodeCheckFailedAlert)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return delay().concatenate(with: verifyPasscode())

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
							label: { TextState(L10n.Splash.PasscodeCheckFailedAlert.retry) }
						)
						ButtonState(
							role: .none,
							action: .send(.openSettingsButtonTapped),
							label: { TextState(L10n.Splash.PasscodeCheckFailedAlert.settings) }
						)
					},
					message: { .init(L10n.Splash.PasscodeCheckFailedAlert.message) }
				)

				return .none
			}

			return .run { send in
				await send(.delegate(.loadProfileOutcome(loadProfile())))
			}
		}
	}

	private func delay() -> EffectTask<Action> {
		.run { _ in
			let durationInMS: Int
			#if DEBUG
			durationInMS = 200
			#else
			durationInMS = 800
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
