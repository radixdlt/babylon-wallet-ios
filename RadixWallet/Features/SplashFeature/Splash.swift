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
		case appeared
		case didTapToUnlock
	}

	public enum InternalAction: Sendable, Equatable {
		case passcodeConfigResult(TaskResult<LocalAuthenticationConfig>)
		case loadedProfile(Profile)
		case accountRecoveryNeeded(TaskResult<Bool>)
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
			return delay().concatenate(with: verifyPasscode()).concatenate(with: boot_sargon_os())

		case .didTapToUnlock:
			state.biometricsCheckFailed = false
			return verifyPasscode()
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

			return .none

		case let .loadedProfile(profile):
			if profile.networks.isEmpty {
				return delegateCompleted()
			} else {
				return checkAccountRecoveryNeeded()
			}

		case let .accountRecoveryNeeded(.failure(error)):
			state.biometricsCheckFailed = true
			errorQueue.schedule(error)
			return .none

		case let .accountRecoveryNeeded(.success(recoveryNeeded)):
			if recoveryNeeded {
				loggerGlobal.notice("Account recovery needed")
			}
			return delegateCompleted()
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

	func delegateCompleted() -> Effect<Action> {
		.run { send in
			await send(.delegate(
				.completed(ProfileStore.shared.profile)
			))
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

	private func boot_sargon_os() -> Effect<Action> {
		.run { send in
			try await SargonOS.creatingShared(
				bootingWith: .creatingShared(drivers: .init(
					bundle: Bundle.main,
					userDefaultsSuite: "group.com.radixpublishing.preview", secureStorageDriver: SargonSecureStorage()
				)
				)
			)

			await send(.internal(.loadedProfile(onboardingClient.loadProfile())))
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

// MARK: - SargonSecureStorage
final class SargonSecureStorage: SecureStorageDriver {
	@Dependency(\.secureStorageClient) var secureStorageClient
	let userDefaults = UserDefaults.Dependency.radix

	func loadData(key: SargonUniFFI.SecureStorageKey) async throws -> SargonUniFFI.BagOfBytes? {
		switch key {
		case .snapshotHeadersList:
			nil
		case .activeProfileId:
			userDefaults.data(key: .activeProfileID)
		case .deviceInfo:
			try secureStorageClient.loadDeviceInfo()?.jsonData()
		case let .deviceFactorSourceMnemonic(factorSourceId):
			try secureStorageClient.loadMnemonicDataByFactorSourceID(.init(factorSourceID: factorSourceId, notifyIfMissing: true))
		case let .profileSnapshot(profileId):
			try secureStorageClient.loadProfileSnapshotData(profileId)
		}
	}

	func saveData(key: SargonUniFFI.SecureStorageKey, data: SargonUniFFI.BagOfBytes) async throws {
		switch key {
		case .snapshotHeadersList:
			return
		case .activeProfileId:
			userDefaults.set(data: data, key: .activeProfileID)
		case .deviceInfo:
			try secureStorageClient.saveDeviceInfo(DeviceInfo(jsonData: data))
		case let .deviceFactorSourceMnemonic(factorSourceId):
			try await secureStorageClient.saveMnemonicForFactorSourceData(factorSourceId, data)
		case let .profileSnapshot(profileId):
			try secureStorageClient.saveProfileSnapshotData(profileId, data)
		}
	}

	func deleteDataForKey(key: SargonUniFFI.SecureStorageKey) async throws {
		//        switch key {
		//        case .snapshotHeadersList:
		//            <#code#>
		//        case .activeProfileId:
		//            <#code#>
		//        case .deviceInfo:
		//            <#code#>
		//        case .deviceFactorSourceMnemonic(let factorSourceId):
		//            <#code#>
		//        case .profileSnapshot(let profileId):
		//            <#code#>
		//        }
	}
}
