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
		public let name: String?
		public let model: FactorSource.LedgerHardwareWallet.DeviceModel
		public var displayName: String {
			if let name {
				return "\(name) (\(model.rawValue))"
			} else {
				return model.rawValue
			}
		}

		public let id: FactorSource.ID
		public let migratedAccounts: NonEmpty<OrderedSet<MigratedAccount>>
	}

	public struct State: Sendable, Hashable {
		public let networkID: NetworkID
		public var unmigrated: OlympiaAccountsValidation

		/// migrated (an before that validated)
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
			self.chooseLedger = .init(allowSelection: true, showHeaders: false)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case skipRestOfTheAccounts
	}

	public enum InternalAction: Sendable, Equatable {
		/// Validated public keys against expected, then migrate...
		case validatedAccounts(Set<OlympiaAccountToMigrate>, LedgerFactorSource)

		/// migrated accounts of validated public keys
		case migratedOlympiaHardwareAccounts(LedgerWithAccounts)
	}

	public enum ChildAction: Sendable, Equatable {
		case chooseLedger(LedgerHardwareDevices.Action)
		case derivePublicKeys(PresentationAction<DerivePublicKeys.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed(
			ledgersWithAccounts: OrderedSet<LedgerWithAccounts>,
			unvalidatedAccounts: Set<OlympiaAccountToMigrate>
		)
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
		switch viewAction {
		case .skipRestOfTheAccounts:
			return .send(.delegate(.completed(
				ledgersWithAccounts: state.ledgersWithAccounts,
				unvalidatedAccounts: state.unmigrated.unvalidated
			)))
		}
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
				return .send(.delegate(.completed(
					ledgersWithAccounts: state.ledgersWithAccounts,
					unvalidatedAccounts: []
				)))
			}

			state.derivePublicKeys = .init(
				derivationPathOption: .knownPaths(
					.init(uncheckedUniqueElements: state.unmigrated.unvalidated.map { $0.path.wrapAsDerivationPath() }),
					networkID: state.networkID
				),
				factorSourceOption: .specific(ledger.factorSource),
				purpose: .importLegacyAccounts
			)
			return .none

		case let .derivePublicKeys(.presented(.delegate(.failedToDerivePublicKey))):
			loggerGlobal.error("ImportOlympiaAccountsAndFactorSource - child derivePublicKeys failed to derive public key")
			state.derivePublicKeys = nil
			return .none

		case let .derivePublicKeys(.presented(.delegate(.derivedPublicKeys(publicKeys, factorSourceID, _)))):
			state.derivePublicKeys = nil
			guard let ledger = state.chooseLedger.ledgers?[id: factorSourceID] else {
				loggerGlobal.error("Failed to find ledger with factor sourceID in local state: \(factorSourceID)")
				return .none
			}
			return validate(derivedPublicKeys: publicKeys, ledger: ledger, state: state)

		default: return .none
		}
	}

	private func validate(
		derivedPublicKeys: OrderedSet<HierarchicalDeterministicPublicKey>,
		ledger: LedgerFactorSource,
		state: State
	) -> EffectTask<Action> {
		.run { [olympiaAccountsToValidate = state.unmigrated.unvalidated] send in
			do {
				let validation = try await validate(derivedPublicKeys: derivedPublicKeys, olympiaAccountsToValidate: olympiaAccountsToValidate)
				await send(.internal(.validatedAccounts(validation.validated, ledger)))
			} catch {
				loggerGlobal.error("Failed to validate accounts, error: \(error)")
				errorQueue.schedule(error)
			}
		}
	}

	private func convertHardwareAccountsToBabylon(
		ledger: LedgerFactorSource,
		validatedAccountsToMigrate olympiaAccounts: Set<OlympiaAccountToMigrate>,
		_ state: State
	) -> EffectTask<Action> {
		loggerGlobal.notice("Converting hardware accounts to babylon...")
		let ledgerName = ledger.label.rawValue

		let model = ledger.model

		return .run { send in
			// Migrates and saved all accounts to Profile
			let migrated = try await importLegacyWalletClient.migrateOlympiaHardwareAccountsToBabylon(
				.init(
					olympiaAccounts: Set(olympiaAccounts),
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

		return .send(.delegate(.completed(
			ledgersWithAccounts: state.ledgersWithAccounts,
			unvalidatedAccounts: []
		)))
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
