import ComposableArchitecture
import FirebaseCrashlytics
import SwiftUI

// MARK: - Splash
struct Splash: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		enum Context: Sendable {
			case appStarted
			case appForegrounded
		}

		let context: Context

		@PresentationState
		var destination: Destination.State?

		var biometricsCheckFailed: Bool = false

		init(
			context: Context = .appStarted,
			destination: Destination.State? = nil
		) {
			self.context = context
			self.destination = destination
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case didTapToUnlock
	}

	enum InternalAction: Sendable, Equatable {
		case passcodeConfigResult(TaskResult<LocalAuthenticationConfig>)
		case biometricsCheckResult(TaskResult<Bool>)
		case advancedLockStateLoaded(isEnabled: Bool)
		case showAppLockMessage
	}

	enum DelegateAction: Sendable, Equatable {
		case completed(ProfileState)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case errorAlert(AlertState<Action.ErrorAlert>)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case errorAlert(ErrorAlert)

			enum ErrorAlert: Sendable, Equatable {
				case retryVerifyPasscodeButtonTapped
				case openSettingsButtonTapped
				case appLockOkButtonTapped
			}
		}

		var body: some ReducerOf<Self> {
			EmptyReducer()
		}
	}

	@Dependency(\.localAuthenticationClient) var localAuthenticationClient
	@Dependency(\.onboardingClient) var onboardingClient
	@Dependency(\.openURL) var openURL
	@Dependency(\.userDefaults) var userDefaults

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			Crashlytics.crashlytics().log("Splash appeared")
			switch state.context {
			case .appStarted:
				return .none
			// return bootSargonOS().concatenate(with: loadAdvancedLockState())
			case .appForegrounded:
				return loadAdvancedLockState()
			}

		case .didTapToUnlock:
			state.biometricsCheckFailed = false
			return verifyPasscode()
		}
	}

	func loadAdvancedLockState() -> Effect<Action> {
		.run { send in
			let profileState = try await onboardingClient.loadProfileState()

			if case let .loaded(profile) = profileState {
				let isAdvancedLockEnabled = profile.appPreferences.security.isAdvancedLockEnabled

				guard #available(iOS 18, *) else {
					// For versions below iOS 18, perform the advanced lock state check
					if isAdvancedLockEnabled {
						#if targetEnvironment(simulator)
						let isEnabled = _XCTIsTesting
						#else
						let isEnabled = true
						#endif
						await send(.internal(.advancedLockStateLoaded(isEnabled: isEnabled)))
					} else {
						await send(.internal(.advancedLockStateLoaded(isEnabled: false)))
					}
					return
				}

				// Starting with iOS 18, the system-provided biometric check will be used
				if isAdvancedLockEnabled, !userDefaults.appLockMessageShown {
					await send(.internal(.showAppLockMessage))
				} else {
					await send(.internal(.advancedLockStateLoaded(isEnabled: false)))
				}
			} else {
				await send(.internal(.advancedLockStateLoaded(isEnabled: false)))
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .advancedLockStateLoaded(isEnabled):
			return isEnabled ? verifyPasscode() : delegateCompleted(context: state.context)

		case let .passcodeConfigResult(result):
			let config = try? result.value

			guard config?.isPasscodeSetUp == true else {
				state.biometricsCheckFailed = true

				state.destination = .errorAlert(.init(
					title: { .init(L10n.Splash.PasscodeCheckFailedAlert.title) },
					actions: {
						ButtonState(
							role: .none,
							action: .send(.retryVerifyPasscodeButtonTapped),
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
			state.destination = .errorAlert(.init(
				title: { .init(L10n.Common.errorAlertTitle) },
				actions: { .default(.init(L10n.Common.ok)) },
				message: { .init(error.localizedDescription) }
			))
			return .none

		case let .biometricsCheckResult(.success(success)):
			guard success else {
				state.biometricsCheckFailed = true
				return .none
			}

			return delegateCompleted(context: state.context)

		case .showAppLockMessage:
			state.destination = .errorAlert(.init(
				title: { .init(L10n.Biometrics.AppLockAvailableAlert.title) },
				actions: {
					.default(
						.init(L10n.Common.dismiss),
						action: .send(.appLockOkButtonTapped)
					)
				},
				message: { .init(L10n.Biometrics.AppLockAvailableAlert.message) }
			))
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .errorAlert(.retryVerifyPasscodeButtonTapped):
			return verifyPasscode()

		case .errorAlert(.openSettingsButtonTapped):
			return .run { _ in
				await openURL(URL(string: UIApplication.openSettingsURLString)!)
			}

		case .errorAlert(.appLockOkButtonTapped):
			userDefaults.setAppLockMessageShown(true)
			return .send(.internal(.advancedLockStateLoaded(isEnabled: false)))
		}
	}

	private func bootSargonOS() -> Effect<Action> {
		.run { _ in
			do {
				Crashlytics.crashlytics().log("Booting Sargon")
				try await SargonOS.creatingShared(
					bootingWith: .creatingShared(
						drivers: .init(
							bundle: Bundle.main,
							userDefaultsSuite: UserDefaults.Dependency.radixSuiteName,
							unsafeStorageKeyMapping: .sargonOSMapping,
							secureStorageDriver: SargonSecureStorage()
						)
					),
					hostInteractor: SargonHostInteractor()
				)
			} catch {
				Crashlytics.crashlytics().log("Failed to boot Sargon \(error)")
				// Ignore error.
				// The only error that can be thrown is SargonOSAlreadyBooted.
				loggerGlobal.error("Did try to boot SargonOS more than once")
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
				// fatalError("Sargon booted")
				try await send(.delegate(.completed(onboardingClient.loadProfileState())))
			case .appForegrounded:
				localAuthenticationClient.setAuthenticatedSuccessfully()
			}
		}
	}
}
