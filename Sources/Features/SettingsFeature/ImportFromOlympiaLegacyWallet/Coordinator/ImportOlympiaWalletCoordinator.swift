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
		public var expectedMnemonicWordCount: BIP39.WordCount? = nil
		public var softwareAccountsToMigrate: AccountsToMigrate? = nil
		public var hardwareAccountsToMigrate: AccountsToMigrate? = nil
		public var mnemonicWithPassphrase: MnemonicWithPassphrase? = nil
		public var migratedAccounts: IdentifiedArrayOf<Profile.Network.Account> = .init()

		public var scanQR: ScanMultipleOlympiaQRCodes.State = .init()
		public var path: StackState<Path.State> = .init()

		public var phase: Phase = .scanning

		public init() {}

		public enum Phase: Sendable, Hashable {
			case scanning
			case showingAccountsToImport(BIP39.WordCount)
		}
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
			scanned: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
			alreadyImported: Set<OlympiaAccountToMigrate.ID>
		)
		case checkedIfOlympiaFactorSourceAlreadyExists(FactorSourceID.FromHash?)
		case migrateHardwareAccounts(NonEmpty<OrderedSet<OlympiaAccountToMigrate>>, NetworkID)
		case validatedOlympiaSoftwareAccounts(
			softwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
			privateHDFactorSource: PrivateHDFactorSource
		)
		case migratedOlympiaSoftwareAccounts(MigratedSoftwareAccounts)
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
			state.expectedMnemonicWordCount = olympiaWallet.mnemonicWordCount
			let scanned = olympiaWallet.accounts
			return .run { send in
				let alreadyImported = await importLegacyWalletClient.findAlreadyImportedIfAny(scanned)

				await send(.internal(.foundAlreadyImportedOlympiaSoftwareAccounts(
					scanned: scanned,
					alreadyImported: alreadyImported
				)))
			}

		case let .path(.element(_, action: pathAction)):
			return reduce(into: &state, pathAction: pathAction)

		default: return .none
		}
	}

	public func reduce(into state: inout State, pathAction: Path.Action) -> EffectTask<Action> {
		switch pathAction {
		case .accountsToImport(.delegate(.continueImport)):
			if let softwareAccounts = state.softwareAccountsToMigrate {
				return migrateSoftwareAccounts(softwareAccounts)
			} else if let hardwareAccounts = state.hardwareAccountsToMigrate {
				return migrateHardwareAccounts(hardwareAccounts)
			} else {
				assertionFailure("Bad implementation, expected to have either 'software' or `hardware` accounts.")
				return .none
			}

		case let .importMnemonic(.delegate(.notSavedInProfile(mnemonicWithPassphrase))):
			state.mnemonicWithPassphrase = mnemonicWithPassphrase
			guard let softwareAccounts = state.softwareAccountsToMigrate else {
				assertionFailure("Bad implementation, expected 'state.accountsToImport.software' to be non-nil.")
				return .none
			}
			return validateSoftwareAccounts(mnemonicWithPassphrase, softwareAccounts: softwareAccounts)

		case let .importOlympiaLedgerAccountsAndFactorSources(.delegate(.completed(ledgersWithAccounts, unvalidatedOlympiaAccounts))):
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

		case .completion(.delegate(.finishedMigration)):
			return .send(.delegate(.finishedMigration))

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .checkedIfOlympiaFactorSourceAlreadyExists(idOfExistingFactorSource):
			guard let idOfExistingFactorSource else {
				let expectedWordCount: BIP39.WordCount = {
					if let expectedMnemonicWordCount = state.expectedMnemonicWordCount {
						return expectedMnemonicWordCount
					}
					assertionFailure("Expected to have set 'expectedMnemonicWordCount'")
					return .twelve
				}()

				let destination: Path.State = .importMnemonic(.init(
					persistAsMnemonicKind: nil,
					wordCount: expectedWordCount
				))

				if state.path.last != destination {
					state.path.append(destination)
				}
				return .none
			}
			guard let softwareAccounts = state.softwareAccountsToMigrate else {
				assertionFailure("Bad implementation, expected 'state.accountsToImport?.software' to be non-nil.")
				return .none
			}
			return convertSoftwareAccountsToBabylon(
				softwareAccounts,
				factorSourceID: idOfExistingFactorSource,
				factorSource: nil
			)

		case let .migrateHardwareAccounts(hardwareAccounts, networkID):
			let destination: Path.State = .importOlympiaLedgerAccountsAndFactorSources(.init(
				hardwareAccounts: hardwareAccounts,
				networkID: networkID
			))
			if state.path.last != destination {
				state.path.append(destination)
			}
			return .none

		case let .foundAlreadyImportedOlympiaSoftwareAccounts(scanned, alreadyImported):
			let notYetImported = scanned.filter { !alreadyImported.contains($0.id) }

			if let accountsToImport = OlympiaAccountsToImport(accounts: notYetImported) {
				state.accountsToImport = accountsToImport

				let destination: Path.State = .accountsToImport(.init(
					scannedAccounts: scanned,
					alreadyImported: alreadyImported
				))
				if state.path.last != destination {
					state.path.append(destination)
				}
			}

			return .none

		case let .validatedOlympiaSoftwareAccounts(softwareAccounts, privateHDFactorSource):
			return convertSoftwareAccountsToBabylon(
				softwareAccounts,
				factorSourceID: privateHDFactorSource.factorSource.id,
				factorSource: privateHDFactorSource
			)

		case let .migratedOlympiaSoftwareAccounts(migratedSoftwareAccounts):
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
		}
	}

	private func migrateSoftwareAccounts(
		_ softwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
	) -> EffectTask<Action> {
		.task {
			let idOfExistingFactorSource = await factorSourcesClient.checkIfHasOlympiaFactorSourceForAccounts(softwareAccounts)
			return .internal(.checkedIfOlympiaFactorSourceAlreadyExists(idOfExistingFactorSource))
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
