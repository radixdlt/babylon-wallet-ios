import AddLedgerFactorSourceFeature
import Cryptography
import DerivePublicKeysFeature
import FactorSourcesClient
import FeaturePrelude
import ImportLegacyWalletClient
import LedgerHardwareDevicesFeature
import LedgerHardwareWalletClient
import NewConnectionFeature
import Profile
import RadixConnectClient
import RadixConnectModels
import SharedModels

// MARK: - ImportOlympiaLedgerAccountsAndFactorSources
public struct ImportOlympiaLedgerAccountsAndFactorSources: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let networkID: NetworkID

		/// Not yet migrated, containing unvalidated and validated accounts.
		public var olympiaAccounts: OlympiaAccountsValidation

		/// Migrated (and before that validated)
		public var migratedAccounts: IdentifiedArrayOf<Profile.Network.Account> = []

		public var knownLedgers: IdentifiedArrayOf<LedgerHardwareWalletFactorSource> = []

		@PresentationState
		public var destinations: Destinations.State?

		public var hasAConnectorExtension: Bool = false

		public init(
			networkID: NetworkID,
			hardwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
		) {
			precondition(hardwareAccounts.allSatisfy { $0.accountType == .hardware })
			self.networkID = networkID
			self.olympiaAccounts = .init(validated: [], unvalidated: Set(hardwareAccounts.elements))
		}
	}

	public struct Destinations: ReducerProtocol {
		public enum State: Sendable, Hashable {
			case noP2PLink(AlertState<NoP2PLinkAlert>)
			case addNewP2PLink(NewConnection.State)
			case nameLedgerAndDerivePublicKeys(NameLedgerAndDerivePublicKeys.State)
		}

		public enum Action: Sendable, Equatable {
			case noP2PLink(NoP2PLinkAlert)
			case addNewP2PLink(NewConnection.Action)
			case nameLedgerAndDerivePublicKeys(NameLedgerAndDerivePublicKeys.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.addNewP2PLink, action: /Action.addNewP2PLink) {
				NewConnection()
			}
			Scope(state: /State.nameLedgerAndDerivePublicKeys, action: /Action.nameLedgerAndDerivePublicKeys) {
				NameLedgerAndDerivePublicKeys()
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
		case continueTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case hasAConnectorExtension(Bool)

		/// Starts the process of adding a new Ledger device
		case useNewLedger(DeviceInfo)

		/// Adds a previously saved device to the list and continues
		case useExistingLedger(LedgerHardwareWalletFactorSource)

		/// Validated public keys against expected, then migrate...
		case validatedAccounts(Set<OlympiaAccountToMigrate>, LedgerHardwareWalletFactorSource.ID)

		/// Migrated accounts of validated public keys
		case migratedOlympiaHardwareAccounts(NonEmpty<[Profile.Network.Account]>)
	}

	public enum ChildAction: Sendable, Equatable {
		case destinations(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case failed(Failure)
		case completed(IdentifiedArrayOf<Profile.Network.Account>)

		public enum Failure: Sendable, Equatable {
			case failedToSaveNewLedger
			case failedToDerivePublicKey
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.importLegacyWalletClient) var importLegacyWalletClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient
	@Dependency(\.p2pLinksClient) var p2pLinksClient

	public init() {}

	public var body: some ReducerProtocolOf<ImportOlympiaLedgerAccountsAndFactorSources> {
		Reduce(core)
			.ifLet(\.$destinations, action: /Action.child .. ChildAction.destinations) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .onFirstTask:
			return checkP2PLinkEffect()

		case .continueTapped:
			guard state.hasAConnectorExtension else {
				state.destinations = .noP2PLink(.noP2Plink)
				return .none
			}

			return .run { send in
				let ledgerInfo = try await ledgerHardwareWalletClient.getDeviceInfo()

				if let ledger = try await factorSourcesClient.getFactorSource(
					id: .init(kind: .ledgerHQHardwareWallet, hash: ledgerInfo.id.data.data),
					as: LedgerHardwareWalletFactorSource.self
				) {
					await send(.internal(.useExistingLedger(ledger)))
				} else {
					await send(.internal(.useNewLedger(ledgerInfo)))
				}
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .hasAConnectorExtension(isConnected):
			state.hasAConnectorExtension = isConnected
			return .none

		case let .useNewLedger(deviceInfo):
			state.destinations = .nameLedgerAndDerivePublicKeys(.init(
				networkID: state.networkID,
				olympiaAccounts: state.olympiaAccounts.unvalidated,
				deviceInfo: deviceInfo
			))
			return .none

		case let .useExistingLedger(ledger):
			state.knownLedgers.append(ledger)
			state.destinations = .nameLedgerAndDerivePublicKeys(.init(
				networkID: state.networkID,
				olympiaAccounts: state.olympiaAccounts.unvalidated,
				ledger: ledger
			))

			return .none

		case let .validatedAccounts(validatedAccounts, ledgerID):
			guard let validatedAccounts = NonEmpty<Set>(validatedAccounts) else {
				struct NoAccountsOnLedgerError: LocalizedError {
					var errorDescription: String? {
						"None of the accounts were fuond on the current Ledger device"
					}
				}

				errorQueue.schedule(NoAccountsOnLedgerError())
				return .none
			}

			for validatedAccount in validatedAccounts {
				state.olympiaAccounts.unvalidated.remove(validatedAccount)
				state.olympiaAccounts.validated.append(contentsOf: validatedAccounts)
			}
			return migrateOlympiaHardwareAccounts(
				ledgerID: ledgerID,
				validatedAccountsToMigrate: validatedAccounts
			)

		case let .migratedOlympiaHardwareAccounts(migratedAccounts):
			loggerGlobal.notice("Adding migrated accounts...")
			state.migratedAccounts.append(contentsOf: migratedAccounts)

			if state.olympiaAccounts.unvalidated.isEmpty {
				loggerGlobal.notice("Finished migrating all accounts.")
				return .send(.delegate(.completed(state.migratedAccounts)))
			}

			loggerGlobal.notice("#\(state.olympiaAccounts.unvalidated) left to migrate...")

			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destinations(.presented(.noP2PLink(noP2PLinkAction))):
			switch noP2PLinkAction {
			case .addNewP2PLinkTapped:
				state.destinations = .addNewP2PLink(.init())
				return .none

			case .cancelTapped:
				return .none
			}

		case let .destinations(.presented(.addNewP2PLink(.delegate(addNewP2PLinkAction)))):
			switch addNewP2PLinkAction {
			case let .newConnection(connectedClient):
				state.destinations = nil

				return .run { _ in
					try await p2pLinksClient.addP2PLink(connectedClient)
				} catch: { error, _ in
					loggerGlobal.error("Failed P2PLink, error \(error)")
					errorQueue.schedule(error)
				}

			case .dismiss:
				state.destinations = nil
				return .none
			}

		case let .destinations(.presented(.nameLedgerAndDerivePublicKeys(.delegate(delegateAction)))):
			switch delegateAction {
			case .failedToSaveNewLedger:
				state.destinations = nil
				return .send(.delegate(.failed(.failedToSaveNewLedger)))

			case let .savedNewLedger(ledger):
				state.knownLedgers.append(ledger)
				return .none

			case .derivePublicKeys(.failedToDerivePublicKey):
				state.destinations = nil
				return .send(.delegate(.failed(.failedToDerivePublicKey)))

			case let .derivePublicKeys(.derivedPublicKeys(publicKeys, factorSourceID, _)):
				state.destinations = nil
				guard let ledgerID = factorSourceID.extract(FactorSourceID.FromHash.self) else {
					loggerGlobal.error("Failed to find ledger with factor sourceID in local state: \(factorSourceID)")
					return .none
				}

				return validate(
					derivedPublicKeys: publicKeys,
					ledgerID: ledgerID,
					olympiaAccountsToValidate: state.olympiaAccounts.unvalidated
				)
			}

		default:
			return .none
		}
	}
}

// MARK: Helper methods

extension ImportOlympiaLedgerAccountsAndFactorSources {
	private func checkP2PLinkEffect() -> EffectTask<Action> {
		.run { send in
			for try await isConnected in await ledgerHardwareWalletClient.isConnectedToAnyConnectorExtension() {
				guard !Task.isCancelled else { return }
				await send(.internal(.hasAConnectorExtension(isConnected)))
			}
		} catch: { error, _ in
			loggerGlobal.error("failed to get links updates, error: \(error)")
		}
	}

	private func validate(
		derivedPublicKeys: [HierarchicalDeterministicPublicKey],
		ledgerID: LedgerHardwareWalletFactorSource.ID,
		olympiaAccountsToValidate: Set<OlympiaAccountToMigrate>
	) -> EffectTask<Action> {
		.run { send in
			do {
				let validation = try await validate(derivedPublicKeys: derivedPublicKeys, olympiaAccountsToValidate: olympiaAccountsToValidate)

				await send(.internal(.validatedAccounts(validation.validated, ledgerID)))
			} catch {
				loggerGlobal.error("Failed to validate accounts, error: \(error)")
				errorQueue.schedule(error)
			}
		}
	}

	private func migrateOlympiaHardwareAccounts(
		ledgerID: LedgerHardwareWalletFactorSource.ID,
		validatedAccountsToMigrate olympiaAccounts: NonEmpty<Set<OlympiaAccountToMigrate>>
	) -> EffectTask<Action> {
		loggerGlobal.notice("Converting hardware accounts to babylon...")
		return .run { send in
			// Migrates and saved all accounts to Profile
			let migrated = try await importLegacyWalletClient.migrateOlympiaHardwareAccountsToBabylon(
				.init(
					olympiaAccounts: olympiaAccounts,
					ledgerFactorSourceID: ledgerID
				)
			)
			let migratedAccounts = migrated.accounts.map(\.babylon)
			loggerGlobal.notice("Converted #\(migratedAccounts.count) accounts to babylon! ✅")

			await send(.internal(.migratedOlympiaHardwareAccounts(migratedAccounts)))
		} catch: { error, _ in
			loggerGlobal.error("Failed to migrate accounts to babylon, error: \(error)")
			errorQueue.schedule(error)
		}
	}

	private func validate(
		derivedPublicKeys: [HierarchicalDeterministicPublicKey],
		olympiaAccountsToValidate: Set<OlympiaAccountToMigrate>
	) async throws -> OlympiaAccountsValidation {
		guard !derivedPublicKeys.isEmpty else {
			loggerGlobal.warning("Response contained no public keys at all.")
			return OlympiaAccountsValidation(
				validated: [],
				unvalidated: olympiaAccountsToValidate
			)
		}

		let derivedKeys: [K1.PublicKey] = derivedPublicKeys.compactMap {
			guard case let .ecdsaSecp256k1(k1Key) = $0.publicKey else {
				return nil
			}
			return k1Key
		}

		var olympiaAccountsToValidate = olympiaAccountsToValidate

		let olympiaAccountsToMigrate = olympiaAccountsToValidate.filter {
			derivedKeys.contains($0.publicKey)
		}

		if olympiaAccountsToMigrate.isEmpty, !olympiaAccountsToValidate.isEmpty, !derivedKeys.isEmpty {
			loggerGlobal.critical("Invalid keys from export format?\nderivedKeys: \(derivedKeys.map { $0.compressedRepresentation.hex() })\nolympiaAccountsToValidate:\(olympiaAccountsToValidate.map(\.publicKey.compressedRepresentation.hex))")
		}

		guard
			let verifiedToBeMigrated = NonEmpty<OrderedSet<OlympiaAccountToMigrate>>(
				rawValue: OrderedSet(uncheckedUniqueElements: olympiaAccountsToMigrate.sorted(by: \.addressIndex))
			)
		else {
			loggerGlobal.warning("No accounts to migrated.")
			return OlympiaAccountsValidation(validated: [], unvalidated: olympiaAccountsToValidate)
		}

		olympiaAccountsToMigrate.forEach { verifiedAccountToMigrate in
			olympiaAccountsToValidate.remove(verifiedAccountToMigrate)
		}

		return OlympiaAccountsValidation(
			validated: olympiaAccountsToMigrate,
			unvalidated: olympiaAccountsToValidate
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

// MARK: - NameLedgerAndDerivePublicKeys
public struct NameLedgerAndDerivePublicKeys: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let networkID: NetworkID

		public let olympiaAccounts: Set<OlympiaAccountToMigrate>

		public var nameLedger: NameLedgerFactorSource.State? = nil

		@PresentationState
		public var derivePublicKeys: DerivePublicKeys.State? = nil

		public init(networkID: NetworkID, olympiaAccounts: Set<OlympiaAccountToMigrate>, deviceInfo: DeviceInfo) {
			self.networkID = networkID
			self.olympiaAccounts = olympiaAccounts
			self.nameLedger = .init(deviceInfo: deviceInfo)
		}

		public init(networkID: NetworkID, olympiaAccounts: Set<OlympiaAccountToMigrate>, ledger: LedgerHardwareWalletFactorSource) {
			self.networkID = networkID
			self.olympiaAccounts = olympiaAccounts

			showDerivePublicKeys(using: ledger)
		}

		mutating func showDerivePublicKeys(using ledger: LedgerHardwareWalletFactorSource) {
			derivePublicKeys = .init(ledger: ledger, olympiaAccounts: olympiaAccounts, networkID: networkID)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case nameLedger(NameLedgerFactorSource.Action)
		case derivePublicKeys(PresentationAction<DerivePublicKeys.Action>)
	}

	public enum InternalAction: Sendable, Equatable {
		/// Saved the newly added Ledger device
		case savedNewLedger(LedgerHardwareWalletFactorSource)
	}

	public enum DelegateAction: Sendable, Equatable {
		case savedNewLedger(LedgerHardwareWalletFactorSource)

		case failedToSaveNewLedger

		case derivePublicKeys(DerivePublicKeys.DelegateAction)
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.nameLedger, action: /Action.child .. ChildAction.nameLedger) {
				NameLedgerFactorSource()
			}
			.ifLet(\.$derivePublicKeys, action: /Action.child .. ChildAction.derivePublicKeys) {
				DerivePublicKeys()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .run { _ in
				await dismiss()
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .nameLedger(.delegate(.complete(ledger))):
			return saveNewLedger(ledger)

		case .nameLedger(.delegate(.failedToCreateLedgerFactorSource)):
			return .send(.delegate(.failedToSaveNewLedger))

		case let .derivePublicKeys(.presented(.delegate(derivePublicKeysAction))):
			return .send(.delegate(.derivePublicKeys(derivePublicKeysAction)))

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .savedNewLedger(ledger):
			state.showDerivePublicKeys(using: ledger)
			return .none
		}
	}

	private func saveNewLedger(_ ledger: LedgerHardwareWalletFactorSource) -> EffectTask<Action> {
		.run { send in
			try await factorSourcesClient.saveFactorSource(ledger.embed())
			loggerGlobal.notice("Saved Ledger factor source! ✅")
			await send(.delegate(.savedNewLedger(ledger)))
			await send(.internal(.savedNewLedger(ledger)))
		} catch: { error, _ in
			loggerGlobal.error("Failed to save Factor Source, error: \(error)")
			errorQueue.schedule(error)
		}
	}
}

extension DerivePublicKeys.State {
	public init(ledger: LedgerHardwareWalletFactorSource, olympiaAccounts: Set<OlympiaAccountToMigrate>, networkID: NetworkID) {
		self.init(
			derivationPathOption: .knownPaths(
				olympiaAccounts.map { $0.path.wrapAsDerivationPath() },
				networkID: networkID
			),
			factorSourceOption: .specific(ledger.embed()),
			purpose: .importLegacyAccounts
		)
	}
}
