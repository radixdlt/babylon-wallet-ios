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
		public var olympiaACcounts: OlympiaAccountsValidation

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
			self.olympiaACcounts = .init(validated: [], unvalidated: Set(hardwareAccounts.elements))
		}
	}

	public struct Destinations: ReducerProtocol {
		public enum State: Sendable, Hashable {
			case derivePublicKeys(DerivePublicKeys.State)
		}

		public enum Action: Sendable, Equatable {
			case derivePublicKeys(DerivePublicKeys.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.derivePublicKeys, action: /Action.derivePublicKeys) {
				DerivePublicKeys()
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case continueTapped
	}

	public enum InternalAction: Sendable, Equatable {
		/// Validated public keys against expected, then migrate...
		case validatedAccounts(NonEmpty<Set<OlympiaAccountToMigrate>>, LedgerHardwareWalletFactorSource)

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

//			ledgerHardwareWalletClient.getDeviceInfo

			let ledger: LedgerHardwareWalletFactorSource = { fatalError() }()

			state.knownLedgers.append(ledger)

			state.destinations = .derivePublicKeys(.init(
				derivationPathOption: .knownPaths(
					.init(uncheckedUniqueElements: state.olympiaACcounts.unvalidated.map { $0.path.wrapAsDerivationPath() }),
					networkID: state.networkID
				),
				factorSourceOption: .specific(ledger.embed()),
				purpose: .importLegacyAccounts
			))
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .validatedAccounts(validatedAccounts, ledger):

			for validatedAccount in validatedAccounts {
				state.olympiaACcounts.unvalidated.remove(validatedAccount)
				state.olympiaACcounts.validated.append(contentsOf: validatedAccounts)
			}
			return convertHardwareAccountsToBabylon(
				ledger: ledger,
				validatedAccountsToMigrate: validatedAccounts
			)

		case let .migratedOlympiaHardwareAccounts(migratedAccounts):
			loggerGlobal.notice("Adding Ledger with accounts...")

			state.migratedAccounts.append(contentsOf: migratedAccounts)

			if state.olympiaACcounts.unvalidated.isEmpty {
				loggerGlobal.notice("Finished migrating all accounts.")
				return .send(.delegate(.completed(state.migratedAccounts)))
			}

			loggerGlobal.notice("state.unmigrated.unvalidated not empty #\(state.olympiaACcounts.unvalidated), need to migrate more accounds...")

			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
//		case let .chooseLedger(.delegate(.choseLedger(ledger))):

		case let .destinations(.presented(presentedAction)):
			switch presentedAction {
			case .derivePublicKeys(.delegate(.failedToDerivePublicKey)):
				loggerGlobal.error("ImportOlympiaAccountsAndFactorSource - child derivePublicKeys failed to derive public key")
				state.destinations = nil
				return .none

			case let .derivePublicKeys(.delegate(.derivedPublicKeys(publicKeys, factorSourceID, _))):
				state.destinations = nil
				guard let id = factorSourceID.extract(FactorSourceID.FromHash.self), let ledger = state.knownLedgers[id: id] else {
					loggerGlobal.error("Failed to find ledger with factor sourceID in local state: \(factorSourceID)")
					return .none
				}

				return validate(
					derivedPublicKeys: publicKeys,
					ledger: ledger,
					olympiaAccountsToValidate: state.olympiaACcounts.unvalidated
				)

			default:
				return .none
			}

		default:
			return .none
		}
	}

	private func validate(
		derivedPublicKeys: OrderedSet<HierarchicalDeterministicPublicKey>,
		ledger: LedgerHardwareWalletFactorSource,
		olympiaAccountsToValidate: Set<OlympiaAccountToMigrate>
	) -> EffectTask<Action> {
		.run { send in
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
		validatedAccountsToMigrate olympiaAccounts: NonEmpty<Set<OlympiaAccountToMigrate>>
	) -> EffectTask<Action> {
		loggerGlobal.notice("Converting hardware accounts to babylon...")
		return .run { send in
			// Migrates and saved all accounts to Profile
			let migrated = try await importLegacyWalletClient.migrateOlympiaHardwareAccountsToBabylon(
				.init(
					olympiaAccounts: olympiaAccounts,
					ledgerFactorSourceID: ledger.id
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
