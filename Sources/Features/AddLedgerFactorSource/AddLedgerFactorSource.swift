import Cryptography
import FactorSourcesClient
import FeaturePrelude
import LedgerHardwareWalletClient
import NewConnectionFeature
import Profile
import RadixConnectClient
import SharedModels

// MARK: - UnnamedLedger
public struct UnnamedLedger: Sendable, Hashable {
	public let id: FactorSource.ID
	public let model: P2P.LedgerHardwareWallet.Model
}

// MARK: - AddLedgerFactorSource
public struct AddLedgerFactorSource: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var ledgerName = ""
		public var isWaitingForResponseFromLedger = false
		public var unnamedDeviceToAdd: UnnamedLedger?

		@PresentationState
		var destination: Destinations.State? = nil

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case sendAddLedgerRequestButtonTapped
		case ledgerNameChanged(String)
		case confirmNameButtonTapped

		public enum CloseLedgerAlreadyExistsDialogAction: Sendable, Hashable {
			case tryAnotherLedger
			case finish(LedgerFactorSource)
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case getDeviceInfoResult(TaskResult<UnnamedLedger>)
		case alreadyExists(LedgerFactorSource)
		case nameLedgerBeforeAddingIt(UnnamedLedger)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed(
			ledger: LedgerFactorSource,
			isNew: Bool
		)
	}

	public enum Destinations {
		public enum State: Sendable, Hashable {
			case closeLedgerAlreadyExistsConfirmationDialog(ConfirmationDialogState<ViewAction.CloseLedgerAlreadyExistsDialogAction>)
		}

		public enum Action: Sendable, Equatable {
			case closeLedgerAlreadyExistsConfirmationDialog(ViewAction.CloseLedgerAlreadyExistsDialogAction)
		}
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .sendAddLedgerRequestButtonTapped:
			return sendAddLedgerRequest(&state)

		case let .ledgerNameChanged(name):
			state.ledgerName = name
			return .none

		case .confirmNameButtonTapped:
			let name = state.ledgerName
			loggerGlobal.notice("Confirmed ledger name: '\(name)' => adding factor source")
			guard let device = state.unnamedDeviceToAdd else {
				assertionFailure("Expected device to name")
				return .none
			}
			return addFactorSourceEffect(name: name, unnamedDeviceToAdd: device)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.closeLedgerAlreadyExistsConfirmationDialog(.finish(ledger)))):
			return .task {
				await dismiss()
				return .delegate(.completed(ledger: ledger, isNew: false))
			}

		case .destination(.presented(.closeLedgerAlreadyExistsConfirmationDialog(.tryAnotherLedger))):
			return sendAddLedgerRequest(&state)

		default:
			return .none
		}
	}

	private func gotDevice(
		_ ledgerDeviceInfo: UnnamedLedger,
		_ state: inout State
	) -> EffectTask<Action> {
		state.isWaitingForResponseFromLedger = false
		loggerGlobal.notice("Successfully received response from CE! \(ledgerDeviceInfo) ✅")
		return .run { send in
			if let existing = try await factorSourcesClient.getFactorSource(id: ledgerDeviceInfo.id) {
				let ledger = try LedgerFactorSource(factorSource: existing)
				await send(.internal(.alreadyExists(ledger)))
			} else {
				// new!
				await send(.internal(.nameLedgerBeforeAddingIt(
					ledgerDeviceInfo
				)))
			}
		} catch: { _, send in
			await send(.internal(.nameLedgerBeforeAddingIt(ledgerDeviceInfo)))
		}
	}

	private func failedToGetDevice(_ state: inout State, error: Swift.Error) -> EffectTask<Action> {
		state.isWaitingForResponseFromLedger = false
		loggerGlobal.error("Failed to get ledger device info: \(error)")
		errorQueue.schedule(error)
		return .none
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .getDeviceInfoResult(.success(ledgerDeviceInfo)):
			return gotDevice(ledgerDeviceInfo, &state)

		case let .getDeviceInfoResult(.failure(error)):
			return failedToGetDevice(&state, error: error)

		case let .alreadyExists(ledger):
			state.destination = .closeLedgerAlreadyExistsConfirmationDialog(
				.init(titleVisibility: .hidden) {
					TextState("")
				} actions: {
					ButtonState(action: .send(.finish(ledger))) {
						TextState("OK")
					}
					ButtonState(role: .cancel, action: .send(.tryAnotherLedger)) {
						TextState("Connect a different Ledger to computer")
					}
				} message: {
					TextState("You have already added this ledger \(ledger.label.rawValue) \(ledger.description.rawValue) on \(ledger.addedOn.ISO8601Format())")
				}
			)
			return .none

		case let .nameLedgerBeforeAddingIt(unnamedDevice):
			state.unnamedDeviceToAdd = unnamedDevice
			return .none
		}
	}

	private func addFactorSourceEffect(
		name: String?,
		unnamedDeviceToAdd device: UnnamedLedger
	) -> EffectTask<Action> {
		let model = FactorSource.LedgerHardwareWallet.DeviceModel(model: device.model)

		loggerGlobal.notice("Creating factor source for Ledger...")

		let ledger = FactorSource.ledger(
			id: device.id,
			model: model,
			name: name
		)

		loggerGlobal.notice("Created factor source for Ledger! adding it now")

		return .run { send in
			try await factorSourcesClient.addOffDeviceFactorSource(ledger.factorSource)
			loggerGlobal.notice("Added Ledger factor source! ✅ ")
			await send(.delegate(.completed(ledger: ledger, isNew: true)))
		} catch: { error, _ in
			loggerGlobal.error("Failed to add Factor Source, error: \(error)")
			errorQueue.schedule(error)
		}
	}

	private func sendAddLedgerRequest(_ state: inout State) -> EffectTask<Action> {
		state.isWaitingForResponseFromLedger = true

		return .task {
			await .internal(.getDeviceInfoResult(TaskResult {
				let info = try await ledgerHardwareWalletClient.getDeviceInfo()
				return .init(id: info.id, model: info.model)
			}))
		}
	}
}

// MARK: - NameLedgerFactorSource
public struct NameLedgerFactorSource: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var ledgerName = ""
		public var isWaitingForResponseFromLedger = false
		public var unnamedDeviceToAdd: UnnamedLedger?

		@PresentationState
		var destination: Destinations.State? = nil

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case sendAddLedgerRequestButtonTapped
		case ledgerNameChanged(String)
		case confirmNameButtonTapped

		public enum CloseLedgerAlreadyExistsDialogAction: Sendable, Hashable {
			case tryAnotherLedger
			case finish(LedgerFactorSource)
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case getDeviceInfoResult(TaskResult<UnnamedLedger>)
		case alreadyExists(LedgerFactorSource)
		case nameLedgerBeforeAddingIt(UnnamedLedger)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed(
			ledger: LedgerFactorSource,
			isNew: Bool
		)
	}

	public enum Destinations {
		public enum State: Sendable, Hashable {
			case closeLedgerAlreadyExistsConfirmationDialog(ConfirmationDialogState<ViewAction.CloseLedgerAlreadyExistsDialogAction>)
		}

		public enum Action: Sendable, Equatable {
			case closeLedgerAlreadyExistsConfirmationDialog(ViewAction.CloseLedgerAlreadyExistsDialogAction)
		}
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .sendAddLedgerRequestButtonTapped:
			return sendAddLedgerRequest(&state)

		case let .ledgerNameChanged(name):
			state.ledgerName = name
			return .none

		case .confirmNameButtonTapped:
			let name = state.ledgerName
			loggerGlobal.notice("Confirmed ledger name: '\(name)' => adding factor source")
			guard let device = state.unnamedDeviceToAdd else {
				assertionFailure("Expected device to name")
				return .none
			}
			return addFactorSourceEffect(name: name, unnamedDeviceToAdd: device)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.closeLedgerAlreadyExistsConfirmationDialog(.finish(ledger)))):
			return .task {
				await dismiss()
				return .delegate(.completed(ledger: ledger, isNew: false))
			}

		case .destination(.presented(.closeLedgerAlreadyExistsConfirmationDialog(.tryAnotherLedger))):
			return sendAddLedgerRequest(&state)

		default:
			return .none
		}
	}

	private func gotDevice(
		_ ledgerDeviceInfo: UnnamedLedger,
		_ state: inout State
	) -> EffectTask<Action> {
		state.isWaitingForResponseFromLedger = false
		loggerGlobal.notice("Successfully received response from CE! \(ledgerDeviceInfo) ✅")
		return .run { send in
			if let existing = try await factorSourcesClient.getFactorSource(id: ledgerDeviceInfo.id) {
				let ledger = try LedgerFactorSource(factorSource: existing)
				await send(.internal(.alreadyExists(ledger)))
			} else {
				// new!
				await send(.internal(.nameLedgerBeforeAddingIt(
					ledgerDeviceInfo
				)))
			}
		} catch: { _, send in
			await send(.internal(.nameLedgerBeforeAddingIt(ledgerDeviceInfo)))
		}
	}

	private func failedToGetDevice(_ state: inout State, error: Swift.Error) -> EffectTask<Action> {
		state.isWaitingForResponseFromLedger = false
		loggerGlobal.error("Failed to get ledger device info: \(error)")
		errorQueue.schedule(error)
		return .none
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .getDeviceInfoResult(.success(ledgerDeviceInfo)):
			return gotDevice(ledgerDeviceInfo, &state)

		case let .getDeviceInfoResult(.failure(error)):
			return failedToGetDevice(&state, error: error)

		case let .alreadyExists(ledger):
			state.destination = .closeLedgerAlreadyExistsConfirmationDialog(
				.init(titleVisibility: .hidden) {
					TextState("")
				} actions: {
					ButtonState(action: .send(.finish(ledger))) {
						TextState("OK")
					}
					ButtonState(role: .cancel, action: .send(.tryAnotherLedger)) {
						TextState("Connect a different Ledger to computer")
					}
				} message: {
					TextState("You have already added this ledger \(ledger.label.rawValue) \(ledger.description.rawValue) on \(ledger.addedOn.ISO8601Format())")
				}
			)
			return .none

		case let .nameLedgerBeforeAddingIt(unnamedDevice):
			state.unnamedDeviceToAdd = unnamedDevice
			return .none
		}
	}

	private func addFactorSourceEffect(
		name: String?,
		unnamedDeviceToAdd device: UnnamedLedger
	) -> EffectTask<Action> {
		let model = FactorSource.LedgerHardwareWallet.DeviceModel(model: device.model)

		loggerGlobal.notice("Creating factor source for Ledger...")

		let ledger = FactorSource.ledger(
			id: device.id,
			model: model,
			name: name
		)

		loggerGlobal.notice("Created factor source for Ledger! adding it now")

		return .run { send in
			try await factorSourcesClient.addOffDeviceFactorSource(ledger.factorSource)
			loggerGlobal.notice("Added Ledger factor source! ✅ ")
			await send(.delegate(.completed(ledger: ledger, isNew: true)))
		} catch: { error, _ in
			loggerGlobal.error("Failed to add Factor Source, error: \(error)")
			errorQueue.schedule(error)
		}
	}

	private func sendAddLedgerRequest(_ state: inout State) -> EffectTask<Action> {
		state.isWaitingForResponseFromLedger = true

		return .task {
			await .internal(.getDeviceInfoResult(TaskResult {
				let info = try await ledgerHardwareWalletClient.getDeviceInfo()
				return .init(id: info.id, model: info.model)
			}))
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
