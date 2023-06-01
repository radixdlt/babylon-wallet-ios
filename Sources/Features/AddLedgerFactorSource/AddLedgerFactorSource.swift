import Cryptography
import FactorSourcesClient
import FeaturePrelude
import LedgerHardwareWalletClient
import NewConnectionFeature
import Profile
import SharedModels

// MARK: - DeviceInfo
public struct DeviceInfo: Sendable, Hashable {
	public let id: HexCodable32Bytes
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
		case alreadyExists(LedgerHardwareWalletFactorSource)
		case proceedToNameDevice(DeviceInfo)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed(LedgerHardwareWalletFactorSource)
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

			if let ledger = try await factorSourcesClient.getFactorSource(
				id: .init(factorSourceKind: .ledgerHQHardwareWallet, hash: ledgerDeviceInfo.id.data.data),
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

	private func failedToGetDevice(_ state: inout State, error: Swift.Error) -> EffectTask<Action> {
		state.isWaitingForResponseFromLedger = false
		loggerGlobal.error("Failed to get ledger device info: \(error)")
		errorQueue.schedule(error)
		return .none
	}

	private func completeWithLedgerEffect(_ ledger: LedgerHardwareWalletFactorSource) -> EffectTask<Action> {
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
			TextState(L10n.AddLedger.AlreadyAddedAlert.title)
		} message: {
			TextState(L10n.AddLedger.AlreadyAddedAlert.message(ledger.hint.name, ledger.hint.model))
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
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .ledgerNameChanged(name):
			state.ledgerName = name
			return .none

		case .confirmNameButtonTapped:
			loggerGlobal.notice("Confirmed ledger name: '\(state.ledgerName)', creating factor source")
			let ledger = LedgerHardwareWalletFactorSource(
				common: .init(
					id: try! .init(factorSourceKind: .ledgerHQHardwareWallet, hash: state.deviceInfo.id.data.data)
				),
				hint: .init(
					name: .init(rawValue: state.ledgerName),
					model: .init(model: state.deviceInfo.model)
				),
				nextDerivationIndicesPerNetwork: .init() // FIXME: Post-MFA remove this
			)

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
