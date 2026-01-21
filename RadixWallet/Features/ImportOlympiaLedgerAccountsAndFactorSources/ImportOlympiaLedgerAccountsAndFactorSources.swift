import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - ImportOlympiaLedgerAccountsAndFactorSources
struct ImportOlympiaLedgerAccountsAndFactorSources: Sendable, FeatureReducer {
	typealias ValidatedAccounts = NonEmpty<Set<OlympiaAccountToMigrate>>

	struct State: Sendable, Hashable {
		let networkID: NetworkID

		/// Not yet migrated, containing unvalidated and validated accounts.
		var olympiaAccounts: OlympiaAccountsValidation

		/// All ledgers that have been on this screen
		var knownLedgers: IdentifiedArrayOf<LedgerHardwareWalletFactorSource> = []

		/// Migrated (and before that validated)
		var migratedAccounts: [MigratedHardwareAccounts] = []

		@PresentationState
		var destination: Destination.State?

		var hasAConnectorExtension: Bool = false

		init(
			networkID: NetworkID,
			hardwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
		) {
			precondition(hardwareAccounts.allSatisfy { $0.accountType == .hardware })
			self.networkID = networkID
			self.olympiaAccounts = .init(validated: [], unvalidated: Set(hardwareAccounts.elements))
		}
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case noP2PLink(AlertState<NoP2PLinkAlert>)
			case addNewP2PLink(NewConnection.State)
			case nameLedger(ImportOlympiaNameLedger.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case noP2PLink(NoP2PLinkAlert)
			case addNewP2PLink(NewConnection.Action)
			case nameLedger(ImportOlympiaNameLedger.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.addNewP2PLink, action: \.addNewP2PLink) {
				NewConnection()
			}
			Scope(state: \.nameLedger, action: \.nameLedger) {
				ImportOlympiaNameLedger()
			}
		}
	}

	enum ViewAction: Sendable, Equatable {
		case onFirstTask
		case continueTapped
	}

	enum InternalAction: Sendable, Equatable {
		case hasAConnectorExtension(Bool)

		/// Starts the process of adding a new Ledger device
		case useNewLedger(LedgerDeviceInfo)

		/// Adds a previously saved device to the list and continues
		case useExistingLedger(LedgerHardwareWalletFactorSource)

		case derivedPublicKeys(FactorSourceIdFromHash, [HierarchicalDeterministicPublicKey])

		// Validates and migrates Olympia hardware accounts
		case processedOlympiaHardwareAccounts(ValidatedAccounts, MigratedHardwareAccounts)
	}

	enum DelegateAction: Sendable, Equatable {
		case failed(Failure)
		case completed(IdentifiedArrayOf<Account>)

		enum Failure: Sendable, Equatable {
			case failedToSaveNewLedger
			case failedToDerivePublicKey
		}
	}

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.importLegacyWalletClient) var importLegacyWalletClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient

	init() {}

	var body: some ReducerOf<ImportOlympiaLedgerAccountsAndFactorSources> {
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask:
			return checkP2PLinkEffect()

		case .continueTapped:
			guard state.hasAConnectorExtension else {
				state.destination = .noP2PLink(.noP2Plink)
				return .none
			}

			return .run { send in
				let ledgerInfo = try await ledgerHardwareWalletClient.getDeviceInfo()

				if let ledger = try await factorSourcesClient.getFactorSource(
					id: FactorSourceID.hash(value: FactorSourceIdFromHash(kind: FactorSourceKind.ledgerHqHardwareWallet, body: Exactly32Bytes(bytes: ledgerInfo.id.data.data))),
					as: LedgerHardwareWalletFactorSource.self
				) {
					await send(.internal(.useExistingLedger(ledger)))
				} else {
					await send(.internal(.useNewLedger(ledgerInfo)))
				}
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .hasAConnectorExtension(isConnected):
			state.hasAConnectorExtension = isConnected
			return .none

		case let .useNewLedger(deviceInfo):
			state.destination = .nameLedger(.init(
				deviceInfo: deviceInfo
			))
			return .none

		case let .useExistingLedger(ledger):
			state.knownLedgers.append(ledger)
			return derivePublicKeysEffect(state: state, factorSourceId: ledger.id)

		case let .derivedPublicKeys(factorSourceId, publicKeys):
			return handleDerivedPublicKeysEffect(state: state, factorSourceId: factorSourceId, publicKeys: publicKeys)

		case let .processedOlympiaHardwareAccounts(validatedAccounts, migratedAccounts):
			for validatedAccount in validatedAccounts {
				state.olympiaAccounts.unvalidated.remove(validatedAccount)
				state.olympiaAccounts.validated.formUnion(validatedAccounts)
			}

			loggerGlobal.notice("Adding migrated accounts...")
			state.migratedAccounts.append(migratedAccounts)

			if state.olympiaAccounts.unvalidated.isEmpty {
				loggerGlobal.notice("Finished migrating all accounts.")
				let babylonAccounts = state.migratedAccounts.collectBabylonAccounts()
				return .send(.delegate(.completed(babylonAccounts)))
			}

			loggerGlobal.notice("#\(state.olympiaAccounts.unvalidated) left to migrate...")

			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .noP2PLink(noP2PLinkAction):
			switch noP2PLinkAction {
			case .addNewP2PLinkTapped:
				state.destination = .addNewP2PLink(.init())
				return .none

			case .cancelTapped:
				return .none
			}

		case let .addNewP2PLink(.delegate(addNewP2PLinkAction)):
			switch addNewP2PLinkAction {
			case .newConnection:
				state.destination = nil
				return .none
			}

		case let .nameLedger(.delegate(delegateAction)):
			switch delegateAction {
			case .failedToSaveNewLedger:
				state.destination = nil
				return .send(.delegate(.failed(.failedToSaveNewLedger)))

			case let .savedNewLedger(ledger):
				return .send(.internal(.useExistingLedger(ledger)))
			}

		default:
			return .none
		}
	}
}

// MARK: Helper methods

extension ImportOlympiaLedgerAccountsAndFactorSources {
	private func checkP2PLinkEffect() -> Effect<Action> {
		.run { send in
			let hasAConnectorExtension = await ledgerHardwareWalletClient.hasAnyLinkedConnector()
			await send(.internal(.hasAConnectorExtension(hasAConnectorExtension)))
		} catch: { error, _ in
			loggerGlobal.error("failed to get links updates, error: \(error)")
		}
	}

	private func derivePublicKeysEffect(state: State, factorSourceId: FactorSourceIdFromHash) -> Effect<Action> {
		let derivationPaths = state.olympiaAccounts.unvalidated.map(\.path.asDerivationPath)
		return .run { send in
			let result = try await SargonOS.shared.derivePublicKeys(derivationPaths: derivationPaths, source: .factorSource(factorSourceId))
			await send(.internal(.derivedPublicKeys(factorSourceId, result)))
		} catch: { _, send in
			await send(.delegate(.failed(.failedToDerivePublicKey)))
		}
	}

	private func handleDerivedPublicKeysEffect(
		state: State,
		factorSourceId: FactorSourceIdFromHash,
		publicKeys: [HierarchicalDeterministicPublicKey]
	) -> Effect<Action> {
		.run { [unvalidated = state.olympiaAccounts.unvalidated] send in
			let (validated, migrated) = try await process(
				derivedPublicKeys: publicKeys,
				ledgerID: factorSourceId,
				olympiaAccountsToValidate: unvalidated
			)
			await send(.internal(.processedOlympiaHardwareAccounts(validated, migrated)))
		} catch: { error, _ in
			loggerGlobal.error("Failed to process Olympia hardware accounts: \(error)")
			errorQueue.schedule(error)
		}
	}

	private func process(
		derivedPublicKeys: [HierarchicalDeterministicPublicKey],
		ledgerID: LedgerHardwareWalletFactorSource.ID,
		olympiaAccountsToValidate: Set<OlympiaAccountToMigrate>
	) async throws -> (ValidatedAccounts, MigratedHardwareAccounts) {
		let validation = try await validate(derivedPublicKeys: derivedPublicKeys, olympiaAccountsToValidate: olympiaAccountsToValidate)

		guard let validatedAccounts = NonEmpty<Set>(validation.validated) else {
			struct NoAccountsOnLedgerError: LocalizedError {
				var errorDescription: String? {
					L10n.ImportOlympiaAccounts.noNewAccounts
				}
			}

			throw NoAccountsOnLedgerError()
		}

		// Migrates and saved all accounts to Profile
		let migrated = try await importLegacyWalletClient.migrateOlympiaHardwareAccountsToBabylon(
			.init(
				olympiaAccounts: validatedAccounts,
				ledgerFactorSourceID: ledgerID
			)
		)

		// Save all accounts
		try await accountsClient.saveVirtualAccounts(migrated.babylonAccounts)

		loggerGlobal.notice("Converted #\(migrated.accounts.count) accounts to babylon! ✅")

		return (validatedAccounts, migrated)
	}

	private func validate(
		derivedPublicKeys: [HierarchicalDeterministicPublicKey],
		olympiaAccountsToValidate: Set<OlympiaAccountToMigrate>
	) async throws -> OlympiaAccountsValidation {
		guard !derivedPublicKeys.isEmpty else {
			loggerGlobal.warning("Response contained no keys at all.")
			return OlympiaAccountsValidation(
				validated: [],
				unvalidated: olympiaAccountsToValidate
			)
		}

		let derivedKeys: [Secp256k1PublicKey] = derivedPublicKeys.compactMap {
			guard case let .secp256k1(k1Key) = $0.publicKey else {
				return nil
			}
			return k1Key
		}

		var olympiaAccountsToValidate = olympiaAccountsToValidate

		let olympiaAccountsToMigrate = olympiaAccountsToValidate.filter {
			derivedKeys.contains($0.publicKey)
		}

		if olympiaAccountsToMigrate.isEmpty, !olympiaAccountsToValidate.isEmpty, !derivedKeys.isEmpty {
			loggerGlobal.critical("Invalid keys from export format?\nderivedKeys: \(derivedKeys.map(\.hex))\nolympiaAccountsToValidate:\(olympiaAccountsToValidate.map(\.publicKey.hex))")
		}

		guard
			let verifiedToBeMigrated = NonEmpty<OrderedSet<OlympiaAccountToMigrate>>(
				rawValue: OrderedSet(
					uncheckedUniqueElements: olympiaAccountsToMigrate
						.sorted(by: \.addressIndex)
				)
			)
		else {
			loggerGlobal.warning("No accounts to migrated.")
			return OlympiaAccountsValidation(validated: [], unvalidated: olympiaAccountsToValidate)
		}

		for verifiedAccountToMigrate in olympiaAccountsToMigrate {
			olympiaAccountsToValidate.remove(verifiedAccountToMigrate)
		}

		return OlympiaAccountsValidation(
			validated: olympiaAccountsToMigrate,
			unvalidated: olympiaAccountsToValidate
		)
	}
}

extension LedgerHardwareWalletModel {
	init(model: P2P.LedgerHardwareWallet.Model) {
		switch model {
		case .nanoS: self = .nanoS
		case .nanoX: self = .nanoX
		case .nanoSPlus: self = .nanoSPlus
		}
	}
}

// MARK: - OlympiaAccountsValidation
struct OlympiaAccountsValidation: Sendable, Hashable {
	var validated: Set<OlympiaAccountToMigrate>
	var unvalidated: Set<OlympiaAccountToMigrate>
	init(validated: Set<OlympiaAccountToMigrate>, unvalidated: Set<OlympiaAccountToMigrate>) {
		self.validated = validated
		self.unvalidated = unvalidated
	}
}
