import ComposableArchitecture
import SwiftUI

// MARK: - Splash
public struct Splash: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Context: Sendable {
			case appStarted
			case appForegrounded
		}

		public let context: Context

		@PresentationState
		public var destination: Destination.State?

		var biometricsCheckFailed: Bool = false

		public init(
			context: Context = .appStarted,
			destination: Destination.State? = nil
		) {
			self.context = context
			self.destination = destination
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case didTapToUnlock
	}

	public enum InternalAction: Sendable, Equatable {
		case passcodeConfigResult(TaskResult<LocalAuthenticationConfig>)
		case biometricsCheckResult(TaskResult<Bool>)
		case checkBiometrics
		case loadingDataCompleted
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed(Profile)
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case passcodeCheckFailed(AlertState<Action.PasscodeCheckFailedAlert>)
		}

		public enum Action: Sendable, Equatable {
			case passcodeCheckFailed(PasscodeCheckFailedAlert)

			public enum PasscodeCheckFailedAlert: Sendable, Equatable {
				case retryButtonTapped
				case openSettingsButtonTapped
			}
		}

		public var body: some ReducerOf<Self> {
			EmptyReducer()
		}
	}

	@Dependency(\.networkSwitchingClient) var networkSwitchingClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.continuousClock) var clock
	@Dependency(\.localAuthenticationClient) var localAuthenticationClient
	@Dependency(\.onboardingClient) var onboardingClient
	@Dependency(\.openURL) var openURL
	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				// FIXME: uncomment
				let isAdvancedLockEnabled = true // await onboardingClient.loadProfile().appPreferences.security.isAdvancedLockEnabled

				// Starting with iOS 18, the system-provided biometric check will be used
				if #unavailable(iOS 18), isAdvancedLockEnabled {
					await send(.internal(.checkBiometrics))
				} else {
					await send(.internal(.loadingDataCompleted))
				}
			}

		case .didTapToUnlock:
			state.biometricsCheckFailed = false
			return verifyPasscode()
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .checkBiometrics:
			return delay().concatenate(with: verifyPasscode()) // TODO: why this delay is needed?

		case let .passcodeConfigResult(result):
			let config = try? result.value

			guard config?.isPasscodeSetUp == true else {
				state.biometricsCheckFailed = true

				state.destination = .passcodeCheckFailed(.init(
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
				))

				return .none
			}

			return authenticateWithBiometrics()

		case let .biometricsCheckResult(.failure(error)):
			state.biometricsCheckFailed = true
			errorQueue.schedule(error)
			return .none

		case let .biometricsCheckResult(.success(success)):
			guard success else {
				state.biometricsCheckFailed = true
				return .none
			}

			return delegateCompleted(context: state.context)

		case .loadingDataCompleted:
			return delegateCompleted(context: state.context)
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .passcodeCheckFailed(.retryButtonTapped):
			verifyPasscode()
		case .passcodeCheckFailed(.openSettingsButtonTapped):
			.run { _ in
				await openURL(URL(string: UIApplication.openSettingsURLString)!)
			}
		}
	}

	private func verifyPasscode() -> Effect<Action> {
		.run { send in
			await send(.internal(.passcodeConfigResult(
				TaskResult {
					try localAuthenticationClient.queryConfig()
				}
			)))
		}
	}

	private func authenticateWithBiometrics() -> Effect<Action> {
		.run { send in
			await send(.internal(.biometricsCheckResult(.init {
				try await localAuthenticationClient.authenticateWithBiometrics()
			})))
		}
	}

	private func delegateCompleted(context: State.Context) -> Effect<Action> {
		.run { send in
			switch context {
			case .appStarted:
				await send(.delegate(.completed(onboardingClient.loadProfile())))
			case .appForegrounded:
				localAuthenticationClient.setAuthenticatedSuccessfully()
			}
		}
	}

	private func delay() -> Effect<Action> {
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
}
