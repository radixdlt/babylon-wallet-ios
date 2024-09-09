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
		case advancedLockStateLoaded(isEnabled: Bool)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed(ProfileState)
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case errorAlert(AlertState<Action.ErrorAlert>)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case errorAlert(ErrorAlert)

			public enum ErrorAlert: Sendable, Equatable {
				case retryVerifyPasscodeButtonTapped
				case openSettingsButtonTapped
			}
		}

		public var body: some ReducerOf<Self> {
			EmptyReducer()
		}
	}

	@Dependency(\.localAuthenticationClient) var localAuthenticationClient
	@Dependency(\.onboardingClient) var onboardingClient
	@Dependency(\.openURL) var openURL

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
				let isAdvancedLockEnabled = await onboardingClient.loadProfile().appPreferences.security.isAdvancedLockEnabled

				// Starting with iOS 18, the system-provided biometric check will be used
				if #unavailable(iOS 18), isAdvancedLockEnabled {
					#if targetEnvironment(simulator)
					let isEnabled = _XCTIsTesting
					#else
					let isEnabled = true
					#endif
					await send(.internal(.advancedLockStateLoaded(isEnabled: isEnabled)))
				} else {
					await send(.internal(.advancedLockStateLoaded(isEnabled: false)))
				}
			}
			.concatenate(with: boot_sargon_os())

		case .didTapToUnlock:
			state.biometricsCheckFailed = false
			return verifyPasscode()
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
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
				title: .init(L10n.Common.errorAlertTitle),
				message: .init(error.localizedDescription),
				buttons: [
					.default(.init(L10n.Common.ok)),
				]
			))
			return .none

		case let .biometricsCheckResult(.success(success)):
			guard success else {
				state.biometricsCheckFailed = true
				return .none
			}

			return delegateCompleted(context: state.context)
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .errorAlert(.retryVerifyPasscodeButtonTapped):
			verifyPasscode()
		case .errorAlert(.openSettingsButtonTapped):
			.run { _ in
				await openURL(URL(string: UIApplication.openSettingsURLString)!)
			}
		}
	}

	private func boot_sargon_os() -> Effect<Action> {
		.run { send in
			_ = ProfileStore.shared
			try await SargonOS.creatingShared(
				bootingWith: .creatingShared(drivers: .init(
					bundle: Bundle.main,
					userDefaultsSuite: "group.com.radixpublishing.preview", secureStorageDriver: SargonSecureStorage()
				)
				)
			)

			await send(.internal(.loadedProfileState(onboardingClient.loadProfileState())))
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
}

// MARK: - SargonSecureStorage
final class SargonSecureStorage: SecureStorageDriver {
	@Dependency(\.secureStorageClient) var secureStorageClient
	let userDefaults = UserDefaults.Dependency.radix

	func loadData(key: SargonUniFFI.SecureStorageKey) async throws -> SargonUniFFI.BagOfBytes? {
		switch key {
		case .hostId:
			return userDefaults.data(key: .hostId)

		case let .deviceFactorSourceMnemonic(factorSourceId):
			return try secureStorageClient.loadMnemonicDataByFactorSourceID(.init(factorSourceID: factorSourceId, notifyIfMissing: true))

		case .profileSnapshot:
			guard let activeProfileId = userDefaults.getActiveProfileID() else {
				return nil
			}

			return try secureStorageClient.loadProfileSnapshotData(activeProfileId)
		}
	}

	func saveData(key: SargonUniFFI.SecureStorageKey, data: SargonUniFFI.BagOfBytes) async throws {
		switch key {
		case .hostId:
			try userDefaults.set(data: data, key: .hostId)
		case let .deviceFactorSourceMnemonic(factorSourceId):
			try await secureStorageClient.saveMnemonicForFactorSourceData(factorSourceId, data)
		case let .profileSnapshot:
			guard let activeProfileId = userDefaults.getActiveProfileID() else {
				return
			}
			try secureStorageClient.saveProfileSnapshotData(activeProfileId, data)
		}
	}

	func deleteDataForKey(key: SargonUniFFI.SecureStorageKey) async throws {
		switch key {
		case .hostId:
			return try userDefaults.remove(.hostId)
		case let .deviceFactorSourceMnemonic(factorSourceId):
			return
		case let .profileSnapshot:
			guard let activeProfileId = userDefaults.getActiveProfileID() else {
				return
			}
			try secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs(profileID: activeProfileId, keepInICloudIfPresent: true)
			return
		}
	}
}
