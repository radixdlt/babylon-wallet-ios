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

// MARK: - UnnamedOlympiaLedgerWithValidatedAccounts
public struct UnnamedOlympiaLedgerWithValidatedAccounts: Sendable, Hashable {
	let unnamedLedger: UnnamedLedger
	let olympiaAccountsValidation: OlympiaAccountsValidation
}

// MARK: - AddLedgerFactorSource
public struct AddLedgerFactorSource: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var isConnectedToAnyCE = false
		public var ledgerName = ""
		public var isWaitingForResponseFromLedger = false
		public var unnamedDeviceToAdd: UnnamedLedger?

		@PresentationState
		var destination: Destinations.State? = nil

		public var olympiaAccountsValidation: OlympiaAccountsValidation?

		public init(
			olympiaAccountsToImport: Set<OlympiaAccountToMigrate>? = nil
		) {
			self.olympiaAccountsValidation = olympiaAccountsToImport.map { OlympiaAccountsValidation(validated: [], unvalidated: $0) } ?? nil
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case addNewP2PLinkButtonTapped
		case sendAddLedgerRequestButtonTapped
		case ledgerNameChanged(String)
		case confirmNameButtonTapped

		public enum CloseLedgerAlreadyExistsDialogAction: Sendable, Hashable {
			case tryAnotherLedger
			case finish(LedgerFactorSource)
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case isConnectedToAnyConnectorExtension(Bool)
		case getDeviceInfoResult(
			TaskResult<UnnamedLedger>
		)
		case getOlympiaDeviceResult(TaskResult<UnnamedOlympiaLedgerWithValidatedAccounts>)
		case alreadyExists(LedgerFactorSource)
		case nameLedgerBeforeAddingIt(UnnamedLedger)
		case saveNewConnection(P2PLink)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed(
			ledger: LedgerFactorSource,
			isNew: Bool,
			olympiaAccountsValidation: OlympiaAccountsValidation?
		)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case addNewP2PLink(NewConnection.State)
			case closeLedgerAlreadyExistsConfirmationDialog(ConfirmationDialogState<ViewAction.CloseLedgerAlreadyExistsDialogAction>)
		}

		public enum Action: Sendable, Equatable {
			case addNewP2PLink(NewConnection.Action)
			case closeLedgerAlreadyExistsConfirmationDialog(ViewAction.CloseLedgerAlreadyExistsDialogAction)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.addNewP2PLink, action: /Action.addNewP2PLink) {
				NewConnection()
			}
		}
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.radixConnectClient) var radixConnectClient
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
		case .task:

			return .run { send in
				for try await isConnected in await ledgerHardwareWalletClient.isConnectedToAnyConnectorExtension() {
					guard !Task.isCancelled else {
						return
					}
					await send(.internal(.isConnectedToAnyConnectorExtension(isConnected)))
				}
			} catch: { error, _ in
				loggerGlobal.error("failed to get links updates, error: \(error)")
			}

		case .addNewP2PLinkButtonTapped:
			state.destination = .addNewP2PLink(.init())
			return .none

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
			return addFactorSource(
				name: name,
				unnamedDeviceToAdd: device,
				olympiaAccountsValidation: state.olympiaAccountsValidation
			)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.addNewP2PLink(.delegate(.newConnection(connectedClient))))):

			state.destination = nil
			return .run { send in
				try await radixConnectClient.storeP2PLink(
					connectedClient
				)
				await send(.internal(.saveNewConnection(connectedClient)))
			} catch: { error, _ in
				loggerGlobal.error("Failed P2PLink, error \(error)")
				errorQueue.schedule(error)
			}
		case .destination(.presented(.addNewP2PLink(.delegate(.dismiss)))):
			state.destination = nil
			return .none

		case let .destination(.presented(.closeLedgerAlreadyExistsConfirmationDialog(.finish(ledger)))):
			return .task { [olympiaAccountsValidation = state.olympiaAccountsValidation] in
				await dismiss()
				return .delegate(.completed(ledger: ledger, isNew: false, olympiaAccountsValidation: olympiaAccountsValidation))
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
		case let .isConnectedToAnyConnectorExtension(isConnectedToAnyCE):
			loggerGlobal.notice("Is connected to any CE?: \(isConnectedToAnyCE)")
			state.isConnectedToAnyCE = isConnectedToAnyCE
			return .none

		case let .getDeviceInfoResult(.success(ledgerDeviceInfo)):
			return gotDevice(ledgerDeviceInfo, &state)

		case let .getDeviceInfoResult(.failure(error)):
			return failedToGetDevice(&state, error: error)

		case let .getOlympiaDeviceResult(.success(deviceWithAccounts)):
			state.olympiaAccountsValidation = deviceWithAccounts.olympiaAccountsValidation
			return gotDevice(deviceWithAccounts.unnamedLedger, &state)

		case let .getOlympiaDeviceResult(.failure(error)):
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

		case .saveNewConnection:
			state.isConnectedToAnyCE = true
			return .none
		}
	}

	private func addFactorSource(
		name: String?,
		unnamedDeviceToAdd device: UnnamedLedger,
		olympiaAccountsValidation: OlympiaAccountsValidation?
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
//			await send(.internal(.addedFactorSource(factorSource, model, name: name)))
			await send(.delegate(.completed(ledger: ledger, isNew: true, olympiaAccountsValidation: olympiaAccountsValidation)))
		} catch: { error, _ in
			loggerGlobal.error("Failed to add Factor Source, error: \(error)")
			errorQueue.schedule(error)
		}
	}

	private func sendAddLedgerRequest(_ state: inout State) -> EffectTask<Action> {
		state.isWaitingForResponseFromLedger = true
		if let olympiaAccountsValidation = state.olympiaAccountsValidation {
			return .task {
				await .internal(.getOlympiaDeviceResult(TaskResult {
					let device = try await ledgerHardwareWalletClient.importOlympiaDevice(olympiaAccountsValidation.unvalidated)
					let olympiaAccountsValidation = try await validate(device, olympiaAccountsToValidate: olympiaAccountsValidation.unvalidated)
					return .init(
						unnamedLedger: .init(id: device.id, model: device.model),
						olympiaAccountsValidation: olympiaAccountsValidation
					)
				}))
			}
		} else {
			return .task {
				await .internal(.getDeviceInfoResult(TaskResult {
					let info = try await ledgerHardwareWalletClient.getDeviceInfo()
					return .init(id: info.id, model: info.model)
				}))
			}
		}
	}

	private func validate(
		_ olympiaDevice: P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.ImportOlympiaDevice,
		olympiaAccountsToValidate: Set<OlympiaAccountToMigrate>
	) async throws -> OlympiaAccountsValidation {
		var olympiaAccountsToValidate = olympiaAccountsToValidate
		guard !olympiaDevice.derivedPublicKeys.isEmpty else {
			loggerGlobal.warning("Response contained no public keys at all.")
			return OlympiaAccountsValidation(
				validated: [],
				unvalidated: olympiaAccountsToValidate
			)
		}
		let derivedKeys = try Set(
			olympiaDevice
				.derivedPublicKeys
				.map { try K1.PublicKey(compressedRepresentation: $0.publicKey.data) }
		)

		let olympiaAccountsToMigrate = olympiaAccountsToValidate.filter {
			derivedKeys.contains($0.publicKey)
		}

		if olympiaAccountsToMigrate.isEmpty, !olympiaAccountsToValidate.isEmpty, !olympiaDevice.derivedPublicKeys.isEmpty {
			loggerGlobal.critical("Invalid keys from export format?\nolympiaDevice.derivedPublicKeys: \(olympiaDevice.derivedPublicKeys.map { $0.publicKey.data.hex() })\nolympiaAccountsToValidate:\(olympiaAccountsToValidate.map(\.publicKey.compressedRepresentation.hex))")
		}

		guard let verifiedToBeMigrated = NonEmpty<OrderedSet<OlympiaAccountToMigrate>>.init(rawValue: OrderedSet(uncheckedUniqueElements: olympiaAccountsToMigrate.sorted(by: \.addressIndex))) else {
			loggerGlobal.warning("No accounts to migrated.")
			return OlympiaAccountsValidation(validated: [], unvalidated: olympiaAccountsToValidate)
		}
		loggerGlobal.notice("Prompting to name ledger with ID=\(olympiaDevice.id) before migrating #\(verifiedToBeMigrated.count) accounts.")

		olympiaAccountsToMigrate.forEach { verifiedAccountToMigrate in
			olympiaAccountsToValidate.remove(verifiedAccountToMigrate)
		}

		return OlympiaAccountsValidation(
			validated: olympiaAccountsToMigrate,
			unvalidated: olympiaAccountsToValidate
		)
	}
}

// MARK: - OlympiaAccountsValidation
public struct OlympiaAccountsValidation: Sendable, Hashable {
	public let validated: Set<OlympiaAccountToMigrate>
	public let unvalidated: Set<OlympiaAccountToMigrate>
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
