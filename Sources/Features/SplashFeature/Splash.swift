import FeaturePrelude
import LocalAuthenticationClient
import OnboardingClient

// MARK: - Splash
public struct Splash: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		public var passcodeCheckFailedAlert: AlertState<ViewAction.PasscodeCheckFailedAlertAction>?
		public var loadProfileOutcome: LoadProfileOutcome?

		public init(
			passcodeCheckFailedAlert: AlertState<ViewAction.PasscodeCheckFailedAlertAction>? = nil,
			loadProfileOutcome: LoadProfileOutcome? = nil
		) {
			self.passcodeCheckFailedAlert = passcodeCheckFailedAlert
			self.loadProfileOutcome = loadProfileOutcome
		}
	}

	public enum ViewAction: Sendable, Equatable {
		public enum PasscodeCheckFailedAlertAction: Sendable, Equatable {
			case cancelButtonTapped
			case openSettingsButtonTapped
		}

		case appeared
		case passcodeCheckFailedAlert(PresentationAction<AlertState<PasscodeCheckFailedAlertAction>, PasscodeCheckFailedAlertAction>)
	}

	public enum InternalAction: Sendable, Equatable {
		case passcodeConfigResult(TaskResult<LocalAuthenticationConfig>)
		case loadProfileOutcome(LoadProfileOutcome)
	}

	public enum DelegateAction: Sendable, Equatable {
		case loadProfileOutcome(LoadProfileOutcome)
	}

	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.localAuthenticationClient) var localAuthenticationClient
	@Dependency(\.onboardingClient.loadProfile) var loadProfile
	@Dependency(\.openURL) var openURL

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.presentationDestination(\.$passcodeCheckFailedAlert, action: /Action.view .. ViewAction.passcodeCheckFailedAlert) {
				EmptyReducer()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				await send(.internal(.loadProfileOutcome(loadProfile())))
			}

		case let .passcodeCheckFailedAlert(.presented(action)):
			switch action {
			case .cancelButtonTapped:
				return notifyDelegate(loadProfileOutcome: state.loadProfileOutcome)
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
					title: { .init(L10n.Splash.Alert.PasscodeCheckFailed.title) },
					actions: {
						ButtonState(
							role: .cancel,
							action: .send(.cancelButtonTapped),
							label: { TextState(L10n.Splash.Alert.PasscodeCheckFailed.cancelButtonTitle) }
						)
						ButtonState(
							role: .none,
							action: .send(.openSettingsButtonTapped),
							label: { TextState(L10n.Splash.Alert.PasscodeCheckFailed.settingsButtonTitle) }
						)
					},
					message: { .init(L10n.Splash.Alert.PasscodeCheckFailed.message) }
				)

				return .none
			}

			return notifyDelegate(loadProfileOutcome: state.loadProfileOutcome)

		case let .loadProfileOutcome(loadProfileOutcome):
			state.loadProfileOutcome = loadProfileOutcome
			return delay().concatenate(with: verifyPasscode())
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
			try? await mainQueue.sleep(for: .milliseconds(durationInMS))
		}
	}

	private func notifyDelegate(loadProfileOutcome: LoadProfileOutcome?) -> EffectTask<Action> {
		precondition(loadProfileOutcome != nil)

		return .run { send in
			await send(.delegate(.loadProfileOutcome(loadProfileOutcome!)))
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
