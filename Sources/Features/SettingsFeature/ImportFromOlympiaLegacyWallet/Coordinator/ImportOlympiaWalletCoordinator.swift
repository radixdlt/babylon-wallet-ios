import Cryptography
import FactorSourcesClient
import FeaturePrelude
import ImportLegacyWalletClient
import ImportMnemonicFeature
import ImportOlympiaLedgerAccountsAndFactorSourcesFeature
import Profile

// MARK: - ImportOlympiaWalletCoordinator
public struct ImportOlympiaWalletCoordinator: Sendable, FeatureReducer {
	public typealias AccountsToMigrate = NonEmpty<OrderedSet<OlympiaAccountToMigrate>>

	public struct State: Sendable, Hashable {
		public var mnemonicWithPassphrase: MnemonicWithPassphrase? = nil
		public var migratedAccounts: IdentifiedArrayOf<Profile.Network.Account> = .init()

		public var scanQR: ScanMultipleOlympiaQRCodes.State = .init()
		public var path: StackState<Path.State> = .init()

		var progress: Progress = .start

		public init() {}
	}

	enum Progress: Sendable, Hashable {
		case start
		case scannedQR(
			scanned: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
			expectedMnemonicWordCount: BIP39.WordCount
		)
		case foundAlreadyImported(
			scanned: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
			expectedMnemonicWordCount: BIP39.WordCount,
			alreadyImported: Set<OlympiaAccountToMigrate.ID>,
			softwareAccountsToMigrate: AccountsToMigrate?,
			hardwareAccountsToMigrate: AccountsToMigrate?
		)
		case checkedIfOlympiaFactorSourceAlreadyExists(
			softwareAccounts: AccountsToMigrate
		)

		case migratedSoftwareAccounts

		case migratedHardwareAccounts

		case importMnemonic(ImportMnemonic)
		case importOlympiaLedgerAccountsAndFactorSources(ImportOlympiaLedgerAccountsAndFactorSources)
		case completion(Completion)

		struct AlreadyImportedAccounts: Sendable, Hashable {
			let ids: Set<OlympiaAccountToMigrate.ID>
		}

		struct NotImportedAcounts: Sendable, Hashable {
			let software: AccountsToMigrate?
			let hardware: AccountsToMigrate?
		}

		struct ExistingFactorSourceID: Sendable, Hashable {
			let id: FactorSourceID.FromHash?
		}

		struct ImportMnemonic: Sendable, Hashable {
			let expectedMnemonicWordCount: BIP39.WordCount
		}

		struct ImportOlympiaLedgerAccountsAndFactorSources: Sendable, Hashable {}

		struct Completion: Sendable, Hashable {}
	}

	public struct Path: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case accountsToImport(AccountsToImport.State)
			case importMnemonic(ImportMnemonic.State)
			case importOlympiaLedgerAccountsAndFactorSources(ImportOlympiaLedgerAccountsAndFactorSources.State)
			case completion(CompletionMigrateOlympiaAccountsToBabylon.State)
		}

		public enum Action: Sendable, Equatable {
			case accountsToImport(AccountsToImport.Action)
			case importMnemonic(ImportMnemonic.Action)
			case importOlympiaLedgerAccountsAndFactorSources(ImportOlympiaLedgerAccountsAndFactorSources.Action)
			case completion(CompletionMigrateOlympiaAccountsToBabylon.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.accountsToImport, action: /Action.accountsToImport) {
				AccountsToImport()
			}
			Scope(state: /State.importMnemonic, action: /Action.importMnemonic) {
				ImportMnemonic()
			}
			Scope(state: /State.importOlympiaLedgerAccountsAndFactorSources, action: /Action.importOlympiaLedgerAccountsAndFactorSources) {
				ImportOlympiaLedgerAccountsAndFactorSources()
			}
			Scope(state: /State.completion, action: /Action.completion) {
				CompletionMigrateOlympiaAccountsToBabylon()
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case scanQR(ScanMultipleOlympiaQRCodes.Action)
		case path(StackActionOf<Path>)
	}

	public enum InternalAction: Sendable, Equatable {
		case foundAlreadyImportedOlympiaSoftwareAccounts(
			Set<OlympiaAccountToMigrate.ID>
		)
		case checkedIfOlympiaFactorSourceAlreadyExists(
			FactorSourceID.FromHash?,
			softwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
		)
		case migrateHardwareAccounts(
			NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
			NetworkID
		)
		case validatedOlympiaSoftwareAccounts(
			softwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
			privateHDFactorSource: PrivateHDFactorSource
		)
		case migratedOlympiaSoftwareAccounts(
			MigratedSoftwareAccounts
		)
	}

	public enum DelegateAction: Sendable, Equatable {
		case finishedMigration
		case dismiss
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.importLegacyWalletClient) var importLegacyWalletClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.scanQR, action: /Action.child .. ChildAction.scanQR) {
			ScanMultipleOlympiaQRCodes()
		}
		Reduce(core)
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .send(.delegate(.dismiss))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .scanQR(.delegate(.finishedScanning(olympiaWallet))):
			let scanned = olympiaWallet.accounts
			state.progress = .scannedQR(.init(
				scanned: scanned,
				expectedMnemonicWordCount: olympiaWallet.mnemonicWordCount
			))

			return .run { send in
				let alreadyImported = await importLegacyWalletClient.findAlreadyImportedIfAny(scanned)
				await send(.internal(.foundAlreadyImportedOlympiaSoftwareAccounts(alreadyImported)))
			}

		case let .path(.element(_, action: pathAction)):
			return reduce(into: &state, pathAction: pathAction)

		default: return .none
		}
	}

	public func reduce(into state: inout State, pathAction: Path.Action) -> EffectTask<Action> {
		switch (pathAction, state.progress) {
		case (.accountsToImport(.delegate(.continueImport)), let .foundAlreadyImported(scanned, imported, notImported)):

			if let softwareAccounts = notImported.software {
				return migrateSoftwareAccounts(softwareAccounts)
			} else if let hardwareAccounts = notImported.hardware {
				return migrateHardwareAccounts(hardwareAccounts)
			} else {
//				state.path.append(
//					.completion(.init(migratedAccounts: <#T##Profile.Network.Accounts#>,
//									  unvalidatedOlympiaHardwareAccounts: <#T##Set<OlympiaAccountToMigrate>?#>))
//				)
				return .none
			}

		case let (.importMnemonic(.delegate(.notSavedInProfile(mnemonicWithPassphrase))), _):
			state.mnemonicWithPassphrase = mnemonicWithPassphrase
			guard let softwareAccounts = state.softwareAccountsToMigrate else {
				assertionFailure("Bad implementation, expected 'state.accountsToImport.software' to be non-nil.")
				return .none
			}
			return validateSoftwareAccounts(mnemonicWithPassphrase, softwareAccounts: softwareAccounts)

		case (let .importOlympiaLedgerAccountsAndFactorSources(.delegate(.completed(ledgersWithAccounts, unvalidatedOlympiaAccounts))), _):
			loggerGlobal.notice("Coordinator, proceeding to completion")
			state.migratedAccounts.append(contentsOf: ledgersWithAccounts.flatMap { $0.migratedAccounts.map(\.babylon) })

			guard let migratedAccounts = Profile.Network.Accounts(rawValue: state.migratedAccounts) else {
				fatalError("bad!")
			}
			let destination: Path.State = .completion(.init(migratedAccounts: migratedAccounts, unvalidatedOlympiaHardwareAccounts: unvalidatedOlympiaAccounts))
			if state.path.last != destination {
				state.path.append(destination)
			}
			return .none

		case (.completion(.delegate(.finishedMigration)), _):
			return .send(.delegate(.finishedMigration))

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch (internalAction, state.progress) {
		case let (.foundAlreadyImportedOlympiaSoftwareAccounts(alreadyImported),
		          .scannedQR(scannedProgress)):
			let notImported = scannedProgress.scanned.filter { !alreadyImported.contains($0.id) }
			let software = NonEmpty(rawValue: OrderedSet(notImported.filter { $0.accountType == .software }))
			let hardware = NonEmpty(rawValue: OrderedSet(notImported.filter { $0.accountType == .hardware }))

			state.progress = .foundAlreadyImported(
				scannedProgress,
				.init(ids: alreadyImported),
				.init(software: software, hardware: hardware)
			)
			state.path.append(
				.accountsToImport(.init(scannedAccounts: scannedProgress.scanned))
			)

			return .none

		case (let .checkedIfOlympiaFactorSourceAlreadyExists(idOfExistingFactorSource, softwareAccounts),
		      let .foundAlreadyImported(scanned, _, _)):
			state.progress = .checkedIfOlympiaFactorSourceAlreadyExists(softwareAccounts: softwareAccounts)

			guard let idOfExistingFactorSource else {
				state.path.append(
					.importMnemonic(.init(
						persistAsMnemonicKind: nil,
						wordCount: scanned.expectedMnemonicWordCount
					))
				)

				return .none
			}
			return convertSoftwareAccountsToBabylon(
				softwareAccounts,
				factorSourceID: idOfExistingFactorSource,
				factorSource: nil
			)

		case (let .migrateHardwareAccounts(hardwareAccounts, networkID),
		      _):
			let destination: Path.State = .importOlympiaLedgerAccountsAndFactorSources(.init(
				hardwareAccounts: hardwareAccounts,
				networkID: networkID
			))
			if state.path.last != destination {
				state.path.append(destination)
			}
			return .none

		case (let .validatedOlympiaSoftwareAccounts(softwareAccounts, privateHDFactorSource),
		      _):
			return convertSoftwareAccountsToBabylon(
				softwareAccounts,
				factorSourceID: privateHDFactorSource.factorSource.id,
				factorSource: privateHDFactorSource
			)

		case let (.migratedOlympiaSoftwareAccounts(migratedSoftwareAccounts),
		          _):
			if let hardwareAccounts = state.hardwareAccountsToMigrate {
				state.migratedAccounts.append(contentsOf: migratedSoftwareAccounts.babylonAccounts.rawValue)
				// also need to add ledger and then migrate hardware account
				return migrateHardwareAccounts(hardwareAccounts)
			} else {
				// no hardware accounts to migrate...
				let destination: Path.State = .completion(.init(migratedAccounts: migratedSoftwareAccounts.babylonAccounts, unvalidatedOlympiaHardwareAccounts: nil))
				if state.path.last != destination {
					state.path.append(destination)
				}
			}
			return .none
		default:
			let msg = "Implementation error, can't accept \(internalAction) with progress \(state.progress)"
			loggerGlobal.critical(.init(stringLiteral: msg))
			assertionFailure(msg)
			return .none
		}
	}

	private func migrateSoftwareAccounts(
		_ softwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
	) -> EffectTask<Action> {
		.task {
			let idOfExistingFactorSource = await factorSourcesClient.checkIfHasOlympiaFactorSourceForAccounts(softwareAccounts)
			return .internal(.checkedIfOlympiaFactorSourceAlreadyExists(idOfExistingFactorSource, softwareAccounts: softwareAccounts))
		}
	}

	private func migrateHardwareAccounts(
		_ hardwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
	) -> EffectTask<Action> {
		.task {
			let networkID = await factorSourcesClient.getCurrentNetworkID()
			return .internal(.migrateHardwareAccounts(hardwareAccounts, networkID))
		}
	}
}

extension ImportOlympiaWalletCoordinator {
	private func validateSoftwareAccounts(
		_ mnemonicWithPassphrase: MnemonicWithPassphrase,
		softwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
	) -> EffectTask<Action> {
		.run { send in
			try mnemonicWithPassphrase.validatePublicKeysOf(
				softwareAccounts: softwareAccounts
			)

			let privateHDFactorSource = try PrivateHDFactorSource(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				factorSource: DeviceFactorSource.olympia(mnemonicWithPassphrase: mnemonicWithPassphrase)
			)
			await send(
				.internal(.validatedOlympiaSoftwareAccounts(
					softwareAccounts: softwareAccounts,
					privateHDFactorSource: privateHDFactorSource
				))
			)

		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	private func convertSoftwareAccountsToBabylon(
		_ olympiaAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
		factorSourceID: FactorSourceID.FromHash,
		factorSource: PrivateHDFactorSource?
	) -> EffectTask<Action> {
		.run { send in
			// Migrates and saved all accounts to Profile
			let migrated = try await importLegacyWalletClient.migrateOlympiaSoftwareAccountsToBabylon(
				.init(
					olympiaAccounts: Set(olympiaAccounts.elements),
					olympiaFactorSouceID: factorSourceID,
					olympiaFactorSource: factorSource
				)
			)

			if let factorSource, let factorSourceToSave = migrated.factorSourceToSave {
				guard try factorSourceToSave.id == FactorSource.id(
					fromPrivateHDFactorSource: factorSource,
					factorSourceKind: .device
				) else {
					throw OlympiaFactorSourceToSaveIDDisrepancy()
				}

				do {
					_ = try await factorSourcesClient.addPrivateHDFactorSource(.init(
						factorSource: factorSource.factorSource.embed(),
						mnemonicWithPasshprase: factorSource.mnemonicWithPassphrase,
						saveIntoProfile: true
					))

				} catch {
					// Check if we have already imported this Mnemonic
					if let existing = try await factorSourcesClient.getFactorSource(id: factorSourceToSave.id.embed()) {
						if existing.kind == .device, existing.supportsOlympia {
							// all good, we had already imported it.
							loggerGlobal.notice("We had already imported this factor source (mnemonic) before.")
						} else {
							let msg = "Failed to save factor source (mnemonic), found existing but it is not of .device kind or does not support olympia params. error: \(error)"
							loggerGlobal.critical(.init(stringLiteral: msg))
							assertionFailure(msg)
							errorQueue.schedule(error)
						}
					} else {
						let msg = "Failed to save factor source (mnemonic) but have already created accounts, error: \(error)"
						loggerGlobal.critical(.init(stringLiteral: msg))
						assertionFailure(msg)
						errorQueue.schedule(error)
					}
				}
			}

			await send(.internal(.migratedOlympiaSoftwareAccounts(migrated)))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}
}

// MARK: - GotNoAccountsToImport
struct GotNoAccountsToImport: Error {}

// MARK: - OlympiaFactorSourceToSaveIDDisrepancy
struct OlympiaFactorSourceToSaveIDDisrepancy: Error {}
