import FeaturePrelude
import LocalAuthenticationClient
import OnboardingClient

// MARK: - Splash
public struct Splash: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		public var biometricsCheckFailedAlert: AlertState<ViewAction.BiometricsCheckFailedAlertAction>?
		public var loadProfileOutcome: LoadProfileOutcome?

		public init(
			biometricsCheckFailedAlert: AlertState<ViewAction.BiometricsCheckFailedAlertAction>? = nil,
			loadProfileOutcome: LoadProfileOutcome? = nil
		) {
			self.biometricsCheckFailedAlert = biometricsCheckFailedAlert
			self.loadProfileOutcome = loadProfileOutcome
		}
	}

	public enum ViewAction: Sendable, Equatable {
		public enum BiometricsCheckFailedAlertAction: Sendable, Equatable {
			case cancelButtonTapped
			case openSettingsButtonTapped
		}

		case appeared
		case biometricsCheckFailedAlert(PresentationAction<AlertState<BiometricsCheckFailedAlertAction>, BiometricsCheckFailedAlertAction>)
	}

	public enum InternalAction: Sendable, Equatable {
		case biometricsConfigResult(TaskResult<LocalAuthenticationConfig>)
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
			.presentationDestination(\.$biometricsCheckFailedAlert, action: /Action.view .. ViewAction.biometricsCheckFailedAlert) {
				EmptyReducer()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				await send(.internal(.loadProfileOutcome(loadProfile())))
			}

		case let .biometricsCheckFailedAlert(.presented(action)):
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
		case .biometricsCheckFailedAlert:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .biometricsConfigResult(result):
			let config = try? result.value

			guard config?.isBiometricsSetUp == true else {
				state.biometricsCheckFailedAlert = .init(
					title: { .init(L10n.Splash.Alert.BiometricsCheckFailed.title) },
					actions: {
						ButtonState(
							role: .cancel,
							action: .send(.cancelButtonTapped),
							label: { TextState(L10n.Splash.Alert.BiometricsCheckFailed.cancelButtonTitle) }
						)
						ButtonState(
							role: .none,
							action: .send(.openSettingsButtonTapped),
							label: { TextState(L10n.Splash.Alert.BiometricsCheckFailed.settingsButtonTitle) }
						)
					},
					message: { .init(L10n.Splash.Alert.BiometricsCheckFailed.message) }
				)

				return .none
			}

			return notifyDelegate(loadProfileOutcome: state.loadProfileOutcome)

		case let .loadProfileOutcome(loadProfileOutcome):
			state.loadProfileOutcome = loadProfileOutcome
			return delay().concatenate(with: verifyBiometrics())
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

	private func verifyBiometrics() -> EffectTask<Action> {
		.run { send in
			await send(.internal(.biometricsConfigResult(
				TaskResult {
					try await localAuthenticationClient.queryConfig()
				}
			)))
		}
	}
}
