import Cryptography
import FactorSourcesClient
import FeaturePrelude
import LedgerHardwareWalletClient
import NewConnectionFeature
import Profile
import SharedModels

public typealias DeviceInfo = P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.GetDeviceInfo

// MARK: - AddLedgerFactorSource
public struct AddLedgerFactorSource: Sendable, FeatureReducer {
	// MARK: AddLedgerFactorSource

	public struct State: Sendable, Hashable {
		public var isWaitingForResponseFromLedger = false
		public var unnamedDeviceToAdd: DeviceInfo?

		@PresentationState
		public var destination: Destinations.State? = nil

		public init() {}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case sendAddLedgerRequestButtonTapped
		case closeButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum InternalAction: Sendable, Equatable {
		case getDeviceInfoResult(TaskResult<DeviceInfo>)
		case alreadyExists(LedgerHardwareWalletFactorSource)
		case proceedToNameDevice(DeviceInfo)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed(LedgerHardwareWalletFactorSource)
		case failedToAddLedger
		case dismiss
	}

	// MARK: Destinations

	public struct Destinations: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case ledgerAlreadyExistsAlert(AlertState<Never>)
			case nameLedger(NameLedgerFactorSource.State)
		}

		public enum Action: Sendable, Equatable {
			case ledgerAlreadyExistsAlert(Never)
			case nameLedger(NameLedgerFactorSource.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.nameLedger, action: /Action.nameLedger) {
				NameLedgerFactorSource()
			}
		}
	}

	// MARK: Reduce

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient
	@Dependency(\.radixConnectClient) var radixConnectClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .sendAddLedgerRequestButtonTapped:
			return sendAddLedgerRequestEffect(&state)

		case .closeButtonTapped:
			return .send(.delegate(.dismiss))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .destination(.presented(.nameLedger(.delegate(.complete(ledger))))):
			return completeWithLedgerEffect(ledger)
		case .destination(.presented(.nameLedger(.delegate(.failedToCreateLedgerFactorSource)))):
			return .send(.delegate(.failedToAddLedger))
		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .getDeviceInfoResult(.success(ledgerDeviceInfo)):
			return gotDeviceEffect(ledgerDeviceInfo, in: &state)

		case let .getDeviceInfoResult(.failure(error)):
			return failedToGetDevice(&state, error: error)

		case let .alreadyExists(ledger):
			state.destination = .ledgerAlreadyExistsAlert(.ledgerAlreadyExists(ledger))
			return .none

		case let .proceedToNameDevice(device):
			state.destination = .nameLedger(.init(deviceInfo: device))
			return .none
		}
	}

	// MARK: Helper methods

	private func sendAddLedgerRequestEffect(_ state: inout State) -> Effect<Action> {
		state.isWaitingForResponseFromLedger = true
		return .run { send in
			let result = await TaskResult {
				try await ledgerHardwareWalletClient.getDeviceInfo()
			}

			await send(.internal(.getDeviceInfoResult(result)))
		}
	}

	private func gotDeviceEffect(_ ledgerDeviceInfo: DeviceInfo, in state: inout State) -> Effect<Action> {
		state.isWaitingForResponseFromLedger = false
		loggerGlobal.notice("Successfully received response from CE! \(ledgerDeviceInfo) ✅")
		return .run { send in

			if let ledger = try await factorSourcesClient.getFactorSource(
				id: .init(kind: .ledgerHQHardwareWallet, hash: ledgerDeviceInfo.id.data.data),
				as: LedgerHardwareWalletFactorSource.self
			) {
				await send(.internal(.alreadyExists(ledger)))
			} else {
				await send(.internal(.proceedToNameDevice(ledgerDeviceInfo)))
			}

		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	private func failedToGetDevice(_ state: inout State, error: Swift.Error) -> Effect<Action> {
		state.isWaitingForResponseFromLedger = false
		loggerGlobal.error("Failed to get ledger device info: \(error)")
		errorQueue.schedule(error)
		return .none
	}

	private func completeWithLedgerEffect(_ ledger: LedgerHardwareWalletFactorSource) -> Effect<Action> {
		.run { send in
			try await factorSourcesClient.saveFactorSource(ledger.embed())
			loggerGlobal.notice("Added Ledger factor source! ✅ ")
			await send(.delegate(.completed(ledger)))
		} catch: { error, _ in
			loggerGlobal.error("Failed to add Factor Source, error: \(error)")
			errorQueue.schedule(error)
		}
	}
}

extension AlertState<Never> {
	static func ledgerAlreadyExists(_ ledger: LedgerHardwareWalletFactorSource) -> AlertState {
		AlertState {
			TextState(L10n.AddLedgerDevice.AlreadyAddedAlert.title)
		} message: {
			TextState(L10n.AddLedgerDevice.AlreadyAddedAlert.message(ledger.hint.name))
		}
	}
}

// MARK: - NameLedgerFactorSource
public struct NameLedgerFactorSource: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let deviceInfo: DeviceInfo
		public var ledgerName = ""

		public init(deviceInfo: DeviceInfo) {
			self.deviceInfo = deviceInfo
		}

		public var nameIsValid: Bool {
			!ledgerName.isEmpty
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case ledgerNameChanged(String)
		case confirmNameButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case complete(LedgerHardwareWalletFactorSource)
		case failedToCreateLedgerFactorSource
	}

	@Dependency(\.errorQueue) var errorQueue
	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .ledgerNameChanged(name):
			state.ledgerName = name
			return .none

		case .confirmNameButtonTapped:
			loggerGlobal.notice("Confirmed ledger name: '\(state.ledgerName)', creating factor source")

			do {
				let ledger = try LedgerHardwareWalletFactorSource.from(
					device: state.deviceInfo,
					name: state.ledgerName
				)
				return .send(.delegate(.complete(ledger)))
			} catch {
				loggerGlobal.error("Failed to created Ledger FactorSource, error: \(error)")
				errorQueue.schedule(error)
				return .send(.delegate(.failedToCreateLedgerFactorSource))
			}
		}
	}
}

extension LedgerHardwareWalletFactorSource {
	static func from(
		device: DeviceInfo,
		name: String
	) throws -> Self {
		try model(
			.init(model: device.model),
			name: name,
			deviceID: device.id
		)
	}
}

extension LedgerHardwareWalletFactorSource.DeviceModel {
	init(model: P2P.LedgerHardwareWallet.Model) {
		switch model {
		case .nanoS: self = .nanoS
		case .nanoX: self = .nanoX
		case .nanoSPlus: self = .nanoSPlus
		}
	}
}
