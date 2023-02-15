import FeaturePrelude
import LocalAuthenticationClient
import ProfileClient

// MARK: - Splash
public struct Splash: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var biometricsCheckFailedAlert: AlertState<ViewAction.BiometricsCheckFailedAlertAction>?
		// TODO: @Nikola
//		public var loadProfileResult: ProfileClient.LoadProfileResult?

		public init(
			biometricsCheckFailedAlert: AlertState<ViewAction.BiometricsCheckFailedAlertAction>? = nil
			// TODO: @Nikola
//			profileResult loadProfileResult: ProfileClient.LoadProfileResult? = nil
		) {
			self.biometricsCheckFailedAlert = biometricsCheckFailedAlert
			// TODO: @Nikola
//			self.loadProfileResult = loadProfileResult
		}
	}

	public enum ViewAction: Sendable, Equatable {
		public enum BiometricsCheckFailedAlertAction: Sendable, Equatable {
			case dismissed
			case cancelButtonTapped
			case openSettingsButtonTapped
		}

		case viewAppeared
		case biometricsCheckFailed(BiometricsCheckFailedAlertAction)
	}

	public enum InternalAction: Sendable, Equatable {
		case biometricsConfigResult(TaskResult<LocalAuthenticationConfig>)
		case loadProfileResult(ProfileClient.LoadProfileResult)
	}

	public enum DelegateAction: Sendable, Equatable {
		case profileResultLoaded(ProfileClient.LoadProfileResult)
	}

	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.localAuthenticationClient) var localAuthenticationClient
	@Dependency(\.profileClient.loadProfile) var loadProfile
	@Dependency(\.openURL) var openURL

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .viewAppeared:
			return .run { send in
				await send(.internal(.loadProfileResult(loadProfile())))
			}

		case let .biometricsCheckFailed(action):
			state.biometricsCheckFailedAlert = nil

			switch action {
			case .dismissed, .cancelButtonTapped:
				// TODO: @Nikola
//				return notifyDelegate(profileResult: state.loadProfileResult)
				return .none

			case .openSettingsButtonTapped:
				#if os(iOS)
				return .run { _ in
					await openURL(URL(string: UIApplication.openSettingsURLString)!)
				}
				#else
				return .none
				#endif
			}
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

			// TODO: @Nikola
//			return notifyDelegate(profileResult: state.loadProfileResult)
			return .none

		case let .loadProfileResult(result):
			// TODO: @Nikola
//			state.loadProfileResult = result
//			return delay().concatenate(with: verifyBiometrics())
			return .none
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

	private func notifyDelegate(profileResult: ProfileClient.LoadProfileResult?) -> EffectTask<Action> {
		precondition(profileResult != nil)

		return .run { send in
			await send(.delegate(.profileResultLoaded(profileResult!)))
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
