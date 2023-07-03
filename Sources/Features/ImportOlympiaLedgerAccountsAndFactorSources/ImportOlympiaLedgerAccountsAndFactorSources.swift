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
	public struct LedgerWithAccounts: Sendable, Hashable {
		public let name: String
		public let model: LedgerHardwareWalletFactorSource.DeviceModel
		public var displayName: String {
			"\(name) (\(model.rawValue))"
		}

		public let id: FactorSourceID.FromHash
		public let migratedAccounts: NonEmpty<OrderedSet<MigratedAccount>>
	}

	public struct State: Sendable, Hashable {
		public let networkID: NetworkID

		/// Not yet migrated, containing unvalidated and validated accounts.
		public var unmigrated: OlympiaAccountsValidation

		/// Migrated (and before that validated)
		public var ledgersWithAccounts: OrderedSet<LedgerWithAccounts> = []

		public var chooseLedger: LedgerHardwareDevices.State

		@PresentationState
		public var derivePublicKeys: DerivePublicKeys.State?

		public init(
			hardwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
			networkID: NetworkID
		) {
			precondition(hardwareAccounts.allSatisfy { $0.accountType == .hardware })
			let accountsValidation = OlympiaAccountsValidation(validated: [], unvalidated: Set(hardwareAccounts.elements))
			self.networkID = networkID
			self.unmigrated = accountsValidation
			self.chooseLedger = .init(context: .importOlympia)
		}
	}

	}

	public enum ViewAction: Sendable, Equatable { }

	public enum InternalAction: Sendable, Equatable {
		/// Validated public keys against expected, then migrate...
		case validatedAccounts(NonEmpty<Set<OlympiaAccountToMigrate>>, LedgerHardwareWalletFactorSource)

		/// migrated accounts of validated public keys
		case migratedOlympiaHardwareAccounts(LedgerWithAccounts)
	}

	public enum ChildAction: Sendable, Equatable {
		case chooseLedger(LedgerHardwareDevices.Action)
		case derivePublicKeys(PresentationAction<DerivePublicKeys.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed(ledgersWithAccounts: OrderedSet<LedgerWithAccounts>)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.importLegacyWalletClient) var importLegacyWalletClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient

	public init() {}

	public var body: some ReducerProtocolOf<ImportOlympiaLedgerAccountsAndFactorSources> {
		Scope(state: \.chooseLedger, action: /Action.child .. ChildAction.chooseLedger) {
			LedgerHardwareDevices()
		}
		Reduce(core)
			.ifLet(\.$derivePublicKeys, action: /Action.child .. ChildAction.derivePublicKeys) {
				DerivePublicKeys()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction { }
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .validatedAccounts(validatedAccounts, ledger):

			for validatedAccount in validatedAccounts {
				state.unmigrated.unvalidated.remove(validatedAccount)
				state.unmigrated.validated.append(contentsOf: validatedAccounts)
			}
			return convertHardwareAccountsToBabylon(
				ledger: ledger,
				validatedAccountsToMigrate: validatedAccounts,
				state
			)

		case let .migratedOlympiaHardwareAccounts(ledgerWithAccounts):
			loggerGlobal.notice("Adding Ledger with accounts...")
			state.ledgersWithAccounts.append(ledgerWithAccounts)

			return continueWithRestOfAccountsIfNeeded(state: &state)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .chooseLedger(.delegate(.choseLedger(ledger))):
			guard !state.unmigrated.unvalidated.isEmpty else {
				return .send(.delegate(.completed(ledgersWithAccounts: state.ledgersWithAccounts)))
			}

			state.derivePublicKeys = .init(
				derivationPathOption: .knownPaths(
					.init(uncheckedUniqueElements: state.unmigrated.unvalidated.map { $0.path.wrapAsDerivationPath() }),
					networkID: state.networkID
				),
				factorSourceOption: .specific(ledger.embed()),
				purpose: .importLegacyAccounts
			)
			return .none

		case .derivePublicKeys(.presented(.delegate(.failedToDerivePublicKey))):
			loggerGlobal.error("ImportOlympiaAccountsAndFactorSource - child derivePublicKeys failed to derive public key")
			state.derivePublicKeys = nil
			return .none

		case let .derivePublicKeys(.presented(.delegate(.derivedPublicKeys(publicKeys, factorSourceID, _)))):
			state.derivePublicKeys = nil
			guard let id = factorSourceID.extract(FactorSourceID.FromHash.self), let ledger = state.chooseLedger.ledgers?[id: id] else {
				loggerGlobal.error("Failed to find ledger with factor sourceID in local state: \(factorSourceID)")
				return .none
			}
			return validate(derivedPublicKeys: publicKeys, ledger: ledger, state: state)

		default: return .none
		}
	}

	private func validate(
		derivedPublicKeys: OrderedSet<HierarchicalDeterministicPublicKey>,
		ledger: LedgerHardwareWalletFactorSource,
		state: State
	) -> EffectTask<Action> {
		.run { [olympiaAccountsToValidate = state.unmigrated.unvalidated] send in
			do {
				let validation = try await validate(derivedPublicKeys: derivedPublicKeys, olympiaAccountsToValidate: olympiaAccountsToValidate)
				guard let validated = NonEmpty<Set>(validation.validated) else {
					throw NoValidatedAccountsError()
				}
				await send(.internal(.validatedAccounts(validated, ledger)))
			} catch {
				loggerGlobal.error("Failed to validate accounts, error: \(error)")
				errorQueue.schedule(error)
			}
		}
	}

	private func convertHardwareAccountsToBabylon(
		ledger: LedgerHardwareWalletFactorSource,
		validatedAccountsToMigrate olympiaAccounts: NonEmpty<Set<OlympiaAccountToMigrate>>,
		_ state: State
	) -> EffectTask<Action> {
		loggerGlobal.notice("Converting hardware accounts to babylon...")
		let ledgerName = ledger.hint.name

		let model = ledger.hint.model

		return .run { send in
			// Migrates and saved all accounts to Profile
			let migrated = try await importLegacyWalletClient.migrateOlympiaHardwareAccountsToBabylon(
				.init(
					olympiaAccounts: olympiaAccounts,
					ledgerFactorSourceID: ledger.id
				)
			)
			loggerGlobal.notice("Converted #\(migrated.babylonAccounts.count) accounts to babylon! ✅")
			let addedLedgerWithAccounts = LedgerWithAccounts(
				name: ledgerName,
				model: model,
				id: ledger.id,
				migratedAccounts: migrated.accounts
			)

			await send(.internal(.migratedOlympiaHardwareAccounts(addedLedgerWithAccounts)))
		} catch: { error, _ in
			loggerGlobal.error("Failed to migrate accounts to babylon, error: \(error)")
			errorQueue.schedule(error)
		}
	}

	private func continueWithRestOfAccountsIfNeeded(state: inout State) -> EffectTask<Action> {
		guard state.unmigrated.unvalidated.isEmpty else {
			loggerGlobal.notice("state.unmigrated.unvalidated not empty #\(state.unmigrated.unvalidated) , need to migrate more accounds...")
			return .none
		}
		loggerGlobal.notice("Finished migrating all accounts.")

		return .send(.delegate(.completed(ledgersWithAccounts: state.ledgersWithAccounts)))
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
