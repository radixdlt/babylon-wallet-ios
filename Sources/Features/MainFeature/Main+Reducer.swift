import AppPreferencesClient
import FeaturePrelude
import GatewaysClient
import HomeFeature
import OverlayWindowClient
import SettingsFeature

// MARK: - Main
public struct Main: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		// MARK: - Components
		public var home: Home.State

		public var isOnMainnet = true

		// MARK: - Destinations
		@PresentationState
		public var destination: Destinations.State?

		public init(
			home: Home.State
		) {
			self.home = home
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case profileUsedOnOtherDeviceErrorAlertAction(ProfileUsedOnOtherDeviceErrorAlertAction)
		public enum ProfileUsedOnOtherDeviceErrorAlertAction: Sendable, Hashable {
			case reclaim
			case deleteProfileOnThisDevice
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case home(Home.Action)
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case removedWallet
		case stoppedUsingProfileOnThisDevice
	}

	public enum InternalAction: Sendable, Equatable {
		case currentGatewayChanged(to: Radix.Gateway)
		case presentUsedOnOtherDeviceWarning(otherDevice: ProfileSnapshot.Header.UsedDeviceInfo)
		case reclaimedProfileOnThisDevice(TaskResult<Prelude.Unit>)
		case stoppedUsingProfileOnThisDevice(TaskResult<Prelude.Unit>)
	}

	public struct Destinations: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case settings(Settings.State)
		}

		public enum Action: Sendable, Equatable {
			case settings(Settings.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.settings, action: /Action.settings) {
				Settings()
			}
		}
	}

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.backupsClient) var backupsClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.continuousClock) var clock
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.home, action: /Action.child .. ChildAction.home) {
			Home()
		}
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .profileUsedOnOtherDeviceErrorAlertAction(.reclaim):
			return .run { send in
				let result = await TaskResult {
					try await backupsClient.reclaimProfileOnThisDevice()
					return Prelude.Unit.instance
				}
				await send(.internal(.reclaimedProfileOnThisDevice(result)))
			}

		case .profileUsedOnOtherDeviceErrorAlertAction(.deleteProfileOnThisDevice):
			return .run { send in
				let result = await TaskResult {
					try await backupsClient.stopUsingProfileOnThisDevice()
					return Prelude.Unit.instance
				}
				await send(.internal(.stoppedUsingProfileOnThisDevice(result)))
			}

		case .task:
			return .run { send in
				for try await gateways in await gatewaysClient.gatewaysValues() {
					guard !Task.isCancelled else { return }
					loggerGlobal.notice("Changed network to: \(gateways.current)")
					await send(.internal(.currentGatewayChanged(to: gateways.current)))
				}
			}.merge(with: .run { send in
				for try await otherDevice in await backupsClient.profileUsedOnOtherDevice() {
					loggerGlobal.notice("Recived event about profile being used on another device...")
					guard !Task.isCancelled else { return }

					await send(.internal(.presentUsedOnOtherDeviceWarning(otherDevice: otherDevice)))
					// A slight delay to allow any modal that may be shown to be dismissed.
					try? await clock.sleep(for: .seconds(0.5))
				}
			})
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .home(.delegate(.displaySettings)):
			state.destination = .settings(.init())
			return .none

		case let .destination(.presented(.settings(.delegate(.deleteProfileAndFactorSources(keepInIcloudIfPresent))))):
			return .run { send in
				try await appPreferencesClient.deleteProfileAndFactorSources(keepInIcloudIfPresent)
				await send(.delegate(.removedWallet))
			} catch: { error, _ in
				loggerGlobal.error("Failed to delete profile: \(error)")
			}

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .presentUsedOnOtherDeviceWarning(otherDevice):
			loggerGlobal.debug("about to present profile used on another device warning")
			return profileUsed(on: otherDevice, state: &state)

		case .stoppedUsingProfileOnThisDevice(.success):
			state.destination = nil
			return .send(.delegate(.stoppedUsingProfileOnThisDevice))

		case let .stoppedUsingProfileOnThisDevice(.failure(error)):
			state.destination = nil
			errorQueue.schedule(FailedToStopUsingProfileOnThisDevice(underlyingError: error))
			return .none

		case .reclaimedProfileOnThisDevice(.success):
			state.destination = nil
			return .none

		case let .reclaimedProfileOnThisDevice(.failure(error)):
			state.destination = nil
			errorQueue.schedule(FailedToReclaimProfileOnThisDevice(underlyingError: error))
			return .none

		case let .currentGatewayChanged(currentGateway):
			state.isOnMainnet = currentGateway.network == .mainnet
			return .none
		}
	}

	func profileUsed(
		on otherDevice: ProfileSnapshot.Header.UsedDeviceInfo,
		state: inout State
	) -> Effect<Action> {
		.run { send in
			let action = await overlayWindowClient.scheduleAlert(
				.init(
					title: { TextState("Use the wallet data on single device only.") }, // FIXME: Strings
					actions: {
						ButtonState(role: .cancel, action: .primaryButtonTapped) {
							TextState("Continue on this iPhone")
						}
						ButtonState(role: .destructive, action: .secondaryButtonTapped) {
							TextState("Delete from this iPhone")
						}
					},
					message: { TextState("The Radix wallet app is not intended to be used with the same wallet data on multiple device. Ensure that you are not doing that.") }
				)
			)
			switch action {
			case .primaryButtonTapped, .dismissed:
				await send(.view(.profileUsedOnOtherDeviceErrorAlertAction(.reclaim)))
			case .secondaryButtonTapped:
				await send(.view(.profileUsedOnOtherDeviceErrorAlertAction(.deleteProfileOnThisDevice)))
			}
		}
	}
}

// MARK: - FailedToStopUsingProfileOnThisDevice
struct FailedToStopUsingProfileOnThisDevice: LocalizedError {
	let underlyingError: String
	init(underlyingError: Error) {
		self.underlyingError = String(describing: underlyingError)
	}

	var errorDescription: String? {
		var description = "Failed to stop using wallet data on this device. Ensure you have backed up your seed phrase and the wallet backup data, then try deleting the wallet from backups in settings or re-install the app"
		#if DEBUG
		description += "\n[DEBUG ONLY]: underlying error: \(underlyingError)"
		#endif
		return description
	}
}

// MARK: - FailedToReclaimProfileOnThisDevice
struct FailedToReclaimProfileOnThisDevice: LocalizedError {
	let underlyingError: String
	init(underlyingError: Error) {
		self.underlyingError = String(describing: underlyingError)
	}

	var errorDescription: String? {
		var description = "Failed to reclaim wallet data on this device. Ensure you have backed up your seed phrase and the wallet backup data, then try deleting the wallet from backups in settings or re-install the app"
		#if DEBUG
		description += "\n[DEBUG ONLY]: underlying error: \(underlyingError)"
		#endif
		return description
	}
}
