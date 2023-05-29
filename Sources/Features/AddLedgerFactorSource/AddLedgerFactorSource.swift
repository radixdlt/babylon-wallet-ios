import Cryptography
import FactorSourcesClient
import FeaturePrelude
import LedgerHardwareWalletClient
import NewConnectionFeature
import Profile
import SharedModels

// MARK: - DeviceInfo
public struct DeviceInfo: Sendable, Hashable {
	public let id: FactorSource.ID
	public let model: P2P.LedgerHardwareWallet.Model
}

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
		case alreadyExists(LedgerFactorSource)
		case proceedToNameDevice(DeviceInfo)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed(LedgerFactorSource)
		case dismiss
	}

	// MARK: Destinations

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case ledgerAlreadyExistsAlert(AlertState<Never>)
			case nameLedger(NameLedgerFactorSource.State)
		}

		public enum Action: Sendable, Equatable {
			case ledgerAlreadyExistsAlert(Never)
			case nameLedger(NameLedgerFactorSource.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.nameLedger, action: /Action.nameLedger) {
				NameLedgerFactorSource()
			}
		}
	}

	// MARK: Reduce

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .sendAddLedgerRequestButtonTapped:
			return sendAddLedgerRequestEffect(&state)

		case .closeButtonTapped:
			return .send(.delegate(.dismiss))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.nameLedger(.delegate(.complete(ledger))))):
			return completeWithLedgerEffect(ledger)

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
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

	private func sendAddLedgerRequestEffect(_ state: inout State) -> EffectTask<Action> {
		state.isWaitingForResponseFromLedger = true
		return .task {
			let result = await TaskResult {
				let info = try await ledgerHardwareWalletClient.getDeviceInfo()
				return DeviceInfo(id: info.id, model: info.model)
			}

			return .internal(.getDeviceInfoResult(result))
		}
	}

	private func gotDeviceEffect(_ ledgerDeviceInfo: DeviceInfo, in state: inout State) -> EffectTask<Action> {
		state.isWaitingForResponseFromLedger = false
		loggerGlobal.notice("Successfully received response from CE! \(ledgerDeviceInfo) ✅")
		return .run { send in
			if let existing = try await factorSourcesClient.getFactorSource(id: ledgerDeviceInfo.id) {
				let ledger = try LedgerFactorSource(factorSource: existing)
				await send(.internal(.alreadyExists(ledger)))
			} else {
				await send(.internal(.proceedToNameDevice(ledgerDeviceInfo)))
			}
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	private func failedToGetDevice(_ state: inout State, error: Swift.Error) -> EffectTask<Action> {
		state.isWaitingForResponseFromLedger = false
		loggerGlobal.error("Failed to get ledger device info: \(error)")
		errorQueue.schedule(error)
		return .none
	}

	private func completeWithLedgerEffect(_ ledger: LedgerFactorSource) -> EffectTask<Action> {
		.run { send in
			try await factorSourcesClient.addOffDeviceFactorSource(ledger.factorSource)
			loggerGlobal.notice("Added Ledger factor source! ✅ ")
			await send(.delegate(.completed(ledger)))
		} catch: { error, _ in
			loggerGlobal.error("Failed to add Factor Source, error: \(error)")
			errorQueue.schedule(error)
		}
	}
}

extension AlertState<Never> {
	static func ledgerAlreadyExists(_ ledger: LedgerFactorSource) -> AlertState {
		AlertState {
			TextState("Ledger is already added") // FIXME: Strings
		} message: {
			TextState("You have already added this ledger \(ledger.label.rawValue) \(ledger.description.rawValue)") // FIXME: Strings
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
		case complete(LedgerFactorSource)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .ledgerNameChanged(name):
			state.ledgerName = name
			return .none

		case .confirmNameButtonTapped:
			loggerGlobal.notice("Confirmed ledger name: '\(state.ledgerName)', creating factor source")
			let ledger = FactorSource.ledger(id: state.deviceInfo.id,
			                                 model: .init(model: state.deviceInfo.model),
			                                 name: state.ledgerName)

			return .send(.delegate(.complete(ledger)))
		}
	}
}

// MARK: - OlympiaAccountsValidation
public struct OlympiaAccountsValidation: Sendable, Hashable {
	public var validated: Set<OlympiaAccountToMigrate>
	public var unvalidated: Set<OlympiaAccountToMigrate>
	public init(validated: Set<OlympiaAccountToMigrate>, unvalidated: Set<OlympiaAccountToMigrate>) {
		self.validated = validated
		self.unvalidated = unvalidated
	}
}

extension FactorSource.LedgerHardwareWallet.DeviceModel {
	init(model: P2P.LedgerHardwareWallet.Model) {
		switch model {
		case .nanoS: self = .nanoS
		case .nanoX: self = .nanoX
		case .nanoSPlus: self = .nanoSPlus
		}
	}
}
