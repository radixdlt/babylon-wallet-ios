import ComposableArchitecture
import SwiftUI

// MARK: - Splash
public struct Splash: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destination.State?

		var biometricsCheckFailed: Bool = false

		public init(
			destination: Destination.State? = nil
		) {
			self.destination = destination
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
		case loadedProfile(Profile)
		case accountRecoveryNeeded(TaskResult<Bool>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed(Profile, accountRecoveryNeeded: Bool)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destination.Action>)
	}

	public struct Destination: Reducer {
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
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destination()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return delay().concatenate(with: verifyPasscode())

		case .didTapToUnlock:
			state.biometricsCheckFailed = false
			return verifyPasscode()

		case let .passcodeCheckFailedAlert(.presented(action)):
			switch action {
			case .retryButtonTapped:
				return verifyPasscode()
			case .openSettingsButtonTapped:
				return .run { _ in
					await openURL(URL(string: UIApplication.openSettingsURLString)!)
				}
			}
		case .passcodeCheckFailedAlert:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
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

			return .run { send in
				await send(.internal(.loadedProfile(onboardingClient.loadProfile())))
			}

		case let .loadedProfile(profile):
			if profile.networks.isEmpty {
				return delegateCompleted(accountRecoveryNeeded: false)
			} else {
				return checkAccountRecoveryNeeded()
			}

		case let .accountRecoveryNeeded(.failure(error)):
			state.biometricsCheckFailed = true
			errorQueue.schedule(error)
			return .none

		case let .accountRecoveryNeeded(.success(recoveryNeeded)):
			return delegateCompleted(accountRecoveryNeeded: recoveryNeeded)
		}
	}

	func delegateCompleted(accountRecoveryNeeded: Bool) -> Effect<Action> {
		.run { send in
			let profile = await onboardingClient.unlockApp()
			await send(.delegate(
				.completed(
					profile,
					accountRecoveryNeeded: accountRecoveryNeeded
				))
			)
		}
	}

	func checkAccountRecoveryNeeded() -> Effect<Action> {
		.run { send in
			await send(.internal(.accountRecoveryNeeded(
				.init {
					try await deviceFactorSourceClient.isAccountRecoveryNeeded()
				}
			)))
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

	private func verifyPasscode() -> Effect<Action> {
		.run { send in
			await send(.internal(.passcodeConfigResult(
				TaskResult {
					try localAuthenticationClient.queryConfig()
				}
			)))
		}
	}
}
