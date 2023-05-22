import AddLedgerFactorSourceFeature
import ChooseLedgerHardwareDeviceFeature
import Cryptography
import FactorSourcesClient
import FeaturePrelude
import ImportLegacyWalletClient
import LedgerHardwareWalletClient
import Profile
import RadixConnectClient
import RadixConnectModels
import SharedModels

// MARK: - ImportOlympiaLedgerAccountsAndFactorSources
public struct ImportOlympiaLedgerAccountsAndFactorSources: Sendable, FeatureReducer {
	public struct LedgerWithAccounts: Sendable, Hashable {
		public let name: String?
		public let isLedgerNew: Bool
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
		public var unmigrated: OlympiaAccountsValidation

		/// migrated (an before that validated)
		public var ledgersWithAccounts: OrderedSet<LedgerWithAccounts> = []

		public var chooseLedger: ChooseLedgerHardwareDevice.State

		public init(
			hardwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
		) {
			precondition(hardwareAccounts.allSatisfy { $0.accountType == .hardware })
			let accountsValidation = OlympiaAccountsValidation(validated: [], unvalidated: Set(hardwareAccounts.elements))
			self.unmigrated = accountsValidation
			self.chooseLedger = .init(olympiaAccountsValidation: accountsValidation)
//			self.addLedgerFactorSource = .init(olympiaAccountsToImport: accountsValidation)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case skipRestOfTheAccounts
	}

	public enum InternalAction: Sendable, Equatable {
		case derivedPublicKeysOnLedger(OrderedSet<HierarchicalDeterministicPublicKey>, LedgerFactorSource)
		case validedAccounts(Set<OlympiaAccountToMigrate>, LedgerFactorSource)
		case migratedOlympiaHardwareAccounts(LedgerWithAccounts)
	}

	public enum ChildAction: Sendable, Equatable {
		case chooseLedger(ChooseLedgerHardwareDevice.Action)
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
			ChooseLedgerHardwareDevice()
		}
		Reduce(core)
//			.ifLet(\.$chooseLedger, action: /Action.child .. ChildAction.addLedgerFactorSource) {
//				AddLedgerFactorSource()
//			}
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
		case let .derivedPublicKeysOnLedger(publicKeys, ledger):
			return validat()

		case let .validedAccounts(validatedAccounts, ledger):

			for validatedAccount in validatedAccounts {
				state.unmigrated.unvalidated.remove(validatedAccount)
			}
			return convertHardwareAccountsToBabylon(
				isLedgerNew: isNew,
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
//		case let .addLedgerFactorSource(.presented(.delegate(.completed(ledger, isNew, olympiaAccountsValidation)))):
//			state.addLedgerFactorSource = nil
		case let .chooseLedger(.delegate(.choseLedger(ledger))):

		default: return .none
		}
	}

	private func deriveKeys(on ledger: LedgerFactorSource) {}

	private func convertHardwareAccountsToBabylon(
		isLedgerNew: Bool,
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
				isLedgerNew: isLedgerNew,
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
			loggerGlobal.notice("state.unverified not empty #\(state.unmigrated.unvalidated) unverfied remain...")
			return .none
		}

		loggerGlobal.notice("state.unverified.isEmpty skipping sending importOlympiaDevice request => delegate completed!")

		return .send(.delegate(.completed(
			ledgersWithAccounts: state.ledgersWithAccounts,
			unvalidatedAccounts: []
		)))
	}

	private func validate(
		derivedPublicKeys: OrderedSet<HierarchicalDeterministicPublicKey>,
		olympiaAccountsToValidate: Set<OlympiaAccountToMigrate>
	) async throws -> OlympiaAccountsValidation {
		//        let derivedKeys = try Set(
		//            olympiaDevice
		//                .derivedPublicKeys
		//                .map { try K1.PublicKey(compressedRepresentation: $0.publicKey.data) }
		//        )

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
