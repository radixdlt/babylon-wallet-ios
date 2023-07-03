import AddLedgerFactorSourceFeature
import Cryptography
import DerivePublicKeysFeature
import FactorSourcesClient
import FeaturePrelude
import ImportLegacyWalletClient
import LedgerHardwareDevicesFeature
import LedgerHardwareWalletClient
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

		public init(
			hardwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
			networkID: NetworkID
		) {
			precondition(hardwareAccounts.allSatisfy { $0.accountType == .hardware })
			self.networkID = networkID
			self.olympiaAccounts = .init(validated: [], unvalidated: Set(hardwareAccounts.elements))
		}
	}

	public struct Destinations: ReducerProtocol {
		public enum State: Sendable, Hashable {
			case nameLedgerAndDerivePublicKeys(NameLedgerAndDerivePublicKeys.State)
			case derivePublicKeys(DerivePublicKeys.State)
		}

		public enum Action: Sendable, Equatable {
			case nameLedgerAndDerivePublicKeys(NameLedgerAndDerivePublicKeys.Action)
			case derivePublicKeys(DerivePublicKeys.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.nameLedgerAndDerivePublicKeys, action: /Action.nameLedgerAndDerivePublicKeys) {
				NameLedgerAndDerivePublicKeys()
			}
			Scope(state: /State.derivePublicKeys, action: /Action.derivePublicKeys) {
				DerivePublicKeys()
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case continueTapped
	}

	public enum InternalAction: Sendable, Equatable {
		/// Starts the process of adding a new Ledger device
		case addNewLedger(DeviceInfo)

		/// Adds a previously saved device to the list and continues
		case addExistingLedger(LedgerHardwareWalletFactorSource)

		/// Validated public keys against expected, then migrate...
		case validatedAccounts(NonEmpty<Set<OlympiaAccountToMigrate>>, LedgerHardwareWalletFactorSource.ID)

		/// Migrated accounts of validated public keys
		case migratedOlympiaHardwareAccounts(NonEmpty<[Profile.Network.Account]>)
	}

	public enum ChildAction: Sendable, Equatable {
		case destinations(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed(IdentifiedArrayOf<Profile.Network.Account>)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.importLegacyWalletClient) var importLegacyWalletClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient

	public init() {}

	public var body: some ReducerProtocolOf<ImportOlympiaLedgerAccountsAndFactorSources> {
		Reduce(core)
			.ifLet(\.$destinations, action: /Action.child .. ChildAction.destinations) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .continueTapped:
			return addLedger()
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .addNewLedger(deviceInfo):
			state.destinations = .nameLedgerAndDerivePublicKeys(.init(deviceInfo: deviceInfo))
			return .none

//		case let .savedNewLedger(ledger):
//			state.destinations = nil
//			return .run { send in
//				// FIXME: Hack to avoid a crash when we show the DerivePublicKeys view too quickly
//				try? await Task.sleep(for: .milliseconds(700))
//				await send(.internal(.addExistingLedger(ledger)))
//			}

		case let .addExistingLedger(ledger):
			return addAccountUsingLedger(in: &state, ledger: ledger)

		case let .validatedAccounts(validatedAccounts, ledgerID):
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
		case let .destinations(.presented(presentedAction)):
			switch presentedAction {
			case .derivePublicKeys(.delegate(.failedToDerivePublicKey)):
				loggerGlobal.error("ImportOlympiaAccountsAndFactorSource - child derivePublicKeys failed to derive public key")
				state.destinations = nil
				return .none

			case let .derivePublicKeys(.delegate(.derivedPublicKeys(publicKeys, factorSourceID, _))):
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

//			case let .nameLedger(.delegate(.complete(ledger))):
//				return saveNewLedger(ledger)
//
//			case .nameLedger(.delegate(.failedToCreateLedgerFactorSource)):
//				return .none
////				return .send(.delegate(.failedToAddLedger))

			default:
				return .none
			}

		default:
			return .none
		}
	}
}

// MARK: Helper methods

extension ImportOlympiaLedgerAccountsAndFactorSources {
	private func addLedger() -> EffectTask<Action> {
		.run { send in
			let ledgerInfo = try await ledgerHardwareWalletClient.getDeviceInfo()

			if let ledger = try await factorSourcesClient.getFactorSource(
				id: .init(kind: .ledgerHQHardwareWallet, hash: ledgerInfo.id.data.data),
				as: LedgerHardwareWalletFactorSource.self
			) {
				await send(.internal(.addExistingLedger(ledger)))
			} else {
				await send(.internal(.addNewLedger(ledgerInfo)))
			}
		}
	}

	private func addAccountUsingLedger(in state: inout State, ledger: LedgerHardwareWalletFactorSource) -> EffectTask<Action> {
		state.knownLedgers.append(ledger)

		state.destinations = .derivePublicKeys(.init(
			derivationPathOption: .knownPaths(
				.init(uncheckedUniqueElements: state.olympiaAccounts.unvalidated.map { $0.path.wrapAsDerivationPath() }),
				networkID: state.networkID
			),
			factorSourceOption: .specific(ledger.embed()),
			purpose: .importLegacyAccounts
		))

		return .none
	}

	private func validate(
		derivedPublicKeys: OrderedSet<HierarchicalDeterministicPublicKey>,
		ledgerID: LedgerHardwareWalletFactorSource.ID,
		olympiaAccountsToValidate: Set<OlympiaAccountToMigrate>
	) -> EffectTask<Action> {
		.run { send in
			do {
				let validation = try await validate(derivedPublicKeys: derivedPublicKeys, olympiaAccountsToValidate: olympiaAccountsToValidate)
				guard let validated = NonEmpty<Set>(validation.validated) else {
					throw NoValidatedAccountsError()
				}
				await send(.internal(.validatedAccounts(validated, ledgerID)))
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
		derivedPublicKeys: OrderedSet<HierarchicalDeterministicPublicKey>,
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

	struct NoValidatedAccountsError: Error {}
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
		public var nameLedger: NameLedgerFactorSource.State?

		public init(deviceInfo: DeviceInfo) {
			self.nameLedger = .init(deviceInfo: deviceInfo)
		}

		public init(ledger: LedgerHardwareWalletFactorSource) {
			self.nameLedger = nil
		}

		@PresentationState
		public var derivePublicKeys: DerivePublicKeys.State? = nil
	}

	public enum ChildAction: Sendable, Equatable {
		case nameLedger(NameLedgerFactorSource.Action)
		case derivePublicKeys(PresentationAction<DerivePublicKeys.Action>)
	}

	public enum InternalAction: Sendable, Equatable {
		/// Saved the newly added Ledger device
		case savedNewLedger(LedgerHardwareWalletFactorSource)
	}

	public typealias DelegateAction = DerivePublicKeys.DelegateAction

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \State.nameLedger, action: /Action.child .. /ChildAction.nameLedger) {
			NameLedgerFactorSource()
		}
		Reduce(core)
			.ifLet(\.$derivePublicKeys, action: /Action.child .. ChildAction.derivePublicKeys) {
				DerivePublicKeys()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .nameLedger(.delegate(.complete(ledger))):
			return saveNewLedger(ledger)

		case .nameLedger(.delegate(.failedToCreateLedgerFactorSource)):
			// TODO: Handle problem
			return .none

		case let .derivePublicKeys(.presented(.delegate(derivePublicKeysAction))):
			return .send(.delegate(derivePublicKeysAction))

		default:
			return .none
		}
	}

	private func saveNewLedger(_ ledger: LedgerHardwareWalletFactorSource) -> EffectTask<Action> {
		.run { send in
			try await factorSourcesClient.saveFactorSource(ledger.embed())
			loggerGlobal.notice("Saved Ledger factor source! ✅ ")
			await send(.internal(.savedNewLedger(ledger)))
		} catch: { error, _ in
			loggerGlobal.error("Failed to save Factor Source, error: \(error)")
			errorQueue.schedule(error)
		}
	}
}

// MARK: NameLedgerAndDerivePublicKeys.View
extension NameLedgerAndDerivePublicKeys {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NameLedgerAndDerivePublicKeys>

		public init(store: StoreOf<NameLedgerAndDerivePublicKeys>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			EmptyView()
		}
	}
}
