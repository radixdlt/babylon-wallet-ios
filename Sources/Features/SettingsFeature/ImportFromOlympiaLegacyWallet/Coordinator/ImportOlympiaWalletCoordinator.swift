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
	public typealias MigratedAccounts = IdentifiedArrayOf<Profile.Network.Account>

	// MARK: State

	public struct State: Sendable, Hashable {
		public var scanQR: ScanMultipleOlympiaQRCodes.State = .init()
		public var path: StackState<Path.State> = .init()

		var progress: Progress = .start

		public init() {}
	}

	// MARK: Progress

	enum Progress: Sendable, Hashable {
		case start
		case scannedQR(ScannedQR)
		case foundAlreadyImported(FoundAlreadyImported)
		case checkedIfOlympiaFactorSourceAlreadyExists(CheckedIfOlympiaFactorSourceAlreadyExists)
		case migratedSoftwareAccounts(MigratedSoftwareAccounts)
		case completion

		struct ScannedQR: Sendable, Hashable {
			let expectedMnemonicWordCount: BIP39.WordCount
			let accountsToMigrate: AccountsToMigrate
		}

		struct FoundAlreadyImported: Sendable, Hashable {
			let networkID: NetworkID
			let expectedMnemonicWordCount: BIP39.WordCount
			let previouslyImported: [OlympiaAccountToMigrate]
			let softwareAccountsToMigrate: AccountsToMigrate?
			let hardwareAccountsToMigrate: AccountsToMigrate?
		}

		struct CheckedIfOlympiaFactorSourceAlreadyExists: Sendable, Hashable {
			let networkID: NetworkID
			let previouslyImported: [OlympiaAccountToMigrate]
			let softwareAccountsToMigrate: AccountsToMigrate
			let hardwareAccountsToMigrate: AccountsToMigrate?
		}

		struct MigratedSoftwareAccounts: Sendable, Hashable {
			let networkID: NetworkID
			let previouslyImported: [OlympiaAccountToMigrate]
			let softwareAccounts: MigratedAccounts
			let hardwareAccountsToMigrate: AccountsToMigrate?
		}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case scanQR(ScanMultipleOlympiaQRCodes.Action)
		case path(StackActionOf<Path>)
	}

	public enum InternalAction: Sendable, Equatable {
		case foundAlreadyImportedOlympiaSoftwareAccounts(
			NetworkID,
			Set<OlympiaAccountToMigrate.ID>
		)
		case checkedIfOlympiaFactorSourceAlreadyExists(
			FactorSourceID.FromHash?,
			softwareAccounts: AccountsToMigrate
		)
		case migratedSoftwareAccountsToBabylon(
			MigratedSoftwareAccounts
		)
	}

	public enum DelegateAction: Sendable, Equatable {
		case finishedMigration
		case dismiss
	}

	// MARK: Path

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

	// MARK: Reducer

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
		case .scanQR(.delegate(.viewAppeared)):
			return scanViewAppeared(in: &state)

		case let .scanQR(.delegate(.finishedScanning(olympiaWallet))):
			return finishedScanning(in: &state, olympiaWallet: olympiaWallet)

		case let .path(.element(_, action: pathAction)):
			return reduce(into: &state, pathAction: pathAction)

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, pathAction: Path.Action) -> EffectTask<Action> {
		switch pathAction {
		case .accountsToImport(.delegate(.continueImport)):
			return continueImporting(in: &state)

		case let .importMnemonic(.delegate(.notSavedInProfile(mnemonicWithPassphrase))):
			return importedMnemonic(in: &state, mnemonicWithPassphrase: mnemonicWithPassphrase)

		case let .importOlympiaLedgerAccountsAndFactorSources(.delegate(.completed(ledgersWithAccounts, unvalidatedAccounts))):
			return importedOlympiaLedgerAccountsAndFactorSources(in: &state, ledgersWithAccounts: ledgersWithAccounts, unvalidated: unvalidatedAccounts)

		case .completion(.delegate(.finishedMigration)):
			return .send(.delegate(.finishedMigration))

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .foundAlreadyImportedOlympiaSoftwareAccounts(networkID, alreadyImported):
			return foundAlreadyImportedAccounts(in: &state, networkID: networkID, alreadyImported: alreadyImported)

		case let .checkedIfOlympiaFactorSourceAlreadyExists(idOfExistingFactorSource, softwareAccounts):
			return checkedIfOlympiaFactorSourceAlreadyExists(in: &state, idOfExistingFactorSource: idOfExistingFactorSource, softwareAccounts: softwareAccounts)

		case let .migratedSoftwareAccountsToBabylon(softwareAccounts):
			return migratedSoftwareAccountsToBabylon(in: &state, softwareAccounts: softwareAccounts)
		}
	}

	// MARK: Main logic

	private func scanViewAppeared(
		in state: inout State
	) -> EffectTask<Action> {
		print("•••• reset scanner")
		state.progress = .start
		return .none
	}

	private func finishedScanning(
		in state: inout State,
		olympiaWallet: ScannedParsedOlympiaWalletToMigrate
	) -> EffectTask<Action> {
		guard case .start = state.progress else { return progressError(state.progress) }

		let scanned = olympiaWallet.accounts
		state.progress = .scannedQR(.init(
			expectedMnemonicWordCount: olympiaWallet.mnemonicWordCount,
			accountsToMigrate: scanned
		))

		return .task {
			let alreadyImported = await importLegacyWalletClient.findAlreadyImportedIfAny(scanned)
			let networkID = await factorSourcesClient.getCurrentNetworkID()
			return .internal(.foundAlreadyImportedOlympiaSoftwareAccounts(networkID, alreadyImported))
		}
	}

	private func foundAlreadyImportedAccounts(
		in state: inout State,
		networkID: NetworkID,
		alreadyImported: Set<OlympiaAccountToMigrate.ID>
	) -> EffectTask<Action> {
		guard case let .scannedQR(progress) = state.progress else { return progressError(state.progress) }

		let previouslyImported = progress.accountsToMigrate.filter { alreadyImported.contains($0.id) }
		let notImported = progress.accountsToMigrate.filter { !alreadyImported.contains($0.id) }
		let softwareAccounts = NonEmpty(rawValue: OrderedSet(notImported.filter { $0.accountType == .software }))
		let hardwareAccounts = NonEmpty(rawValue: OrderedSet(notImported.filter { $0.accountType == .hardware }))

		state.progress = .foundAlreadyImported(.init(
			networkID: networkID,
			expectedMnemonicWordCount: progress.expectedMnemonicWordCount,
			previouslyImported: previouslyImported,
			softwareAccountsToMigrate: softwareAccounts,
			hardwareAccountsToMigrate: hardwareAccounts
		))

		state.path.append(
			.accountsToImport(.init(
				networkID: networkID,
				scannedAccounts: progress.accountsToMigrate
			))
		)
		return .none
	}

	private func continueImporting(
		in state: inout State
	) -> EffectTask<Action> {
		guard case let .foundAlreadyImported(progress) = state.progress else { return progressError(state.progress) }

		if let softwareAccounts = progress.softwareAccountsToMigrate {
			return checkIfOlympiaFactorSourceAlreadyExists(softwareAccounts)
		}

		state.progress = .migratedSoftwareAccounts(.init(
			networkID: progress.networkID,
			previouslyImported: progress.previouslyImported,
			softwareAccounts: [],
			hardwareAccountsToMigrate: progress.hardwareAccountsToMigrate
		))

		return migrateHardwareAccounts(in: &state)
	}

	private func checkIfOlympiaFactorSourceAlreadyExists(
		_ softwareAccounts: AccountsToMigrate
	) -> EffectTask<Action> {
		.task {
			let idOfExistingFactorSource = await factorSourcesClient.checkIfHasOlympiaFactorSourceForAccounts(softwareAccounts)
			return .internal(.checkedIfOlympiaFactorSourceAlreadyExists(idOfExistingFactorSource, softwareAccounts: softwareAccounts))
		}
	}

	private func checkedIfOlympiaFactorSourceAlreadyExists(
		in state: inout State,
		idOfExistingFactorSource: FactorSourceID.FromHash?,
		softwareAccounts: AccountsToMigrate
	) -> EffectTask<Action> {
		guard case let .foundAlreadyImported(progress) = state.progress else { return progressError(state.progress) }

		state.progress = .checkedIfOlympiaFactorSourceAlreadyExists(.init(
			networkID: progress.networkID,
			previouslyImported: progress.previouslyImported,
			softwareAccountsToMigrate: softwareAccounts,
			hardwareAccountsToMigrate: progress.hardwareAccountsToMigrate
		))

		if let idOfExistingFactorSource {
			return migrateSoftwareAccountsToBabylon(
				softwareAccounts,
				factorSourceID: idOfExistingFactorSource,
				factorSource: nil
			)
		}

		state.path.append(
			.importMnemonic(.init(
				persistAsMnemonicKind: nil,
				wordCount: progress.expectedMnemonicWordCount
			))
		)

		return .none
	}

	private func importedMnemonic(
		in state: inout State,
		mnemonicWithPassphrase: MnemonicWithPassphrase
	) -> EffectTask<Action> {
		guard case let .checkedIfOlympiaFactorSourceAlreadyExists(progress) = state.progress else { return progressError(state.progress) }

		do {
			try mnemonicWithPassphrase.validatePublicKeysOf(
				softwareAccounts: progress.softwareAccountsToMigrate
			)

			let privateHDFactorSource = try PrivateHDFactorSource(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				factorSource: DeviceFactorSource.olympia(mnemonicWithPassphrase: mnemonicWithPassphrase)
			)

			return migrateSoftwareAccountsToBabylon(
				progress.softwareAccountsToMigrate,
				factorSourceID: privateHDFactorSource.factorSource.id,
				factorSource: privateHDFactorSource
			)
		} catch {
			errorQueue.schedule(error)
			return .none
		}
	}

	private func migrateSoftwareAccountsToBabylon(
		_ olympiaAccounts: AccountsToMigrate,
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

			await send(.internal(.migratedSoftwareAccountsToBabylon(migrated)))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	public func migratedSoftwareAccountsToBabylon(
		in state: inout State,
		softwareAccounts: MigratedSoftwareAccounts
	) -> EffectTask<Action> {
		guard case let .checkedIfOlympiaFactorSourceAlreadyExists(progress) = state.progress else { return progressError(state.progress) }

		state.progress = .migratedSoftwareAccounts(.init(
			networkID: progress.networkID,
			previouslyImported: progress.previouslyImported,
			softwareAccounts: softwareAccounts.babylonAccounts.rawValue,
			hardwareAccountsToMigrate: progress.hardwareAccountsToMigrate
		))

		return migrateHardwareAccounts(in: &state)
	}

	private func migrateHardwareAccounts(
		in state: inout State
	) -> EffectTask<Action> {
		guard case let .migratedSoftwareAccounts(progress) = state.progress else { return progressError(state.progress) }

		if let hardwareAccounts = progress.hardwareAccountsToMigrate {
			state.path.append(
				.importOlympiaLedgerAccountsAndFactorSources(.init(
					hardwareAccounts: hardwareAccounts,
					networkID: progress.networkID
				))
			)
		} else {
			state.path.append(
				.completion(.init(
					previouslyMigratedAccounts: progress.previouslyImported,
					migratedAccounts: progress.softwareAccounts,
					unvalidatedOlympiaHardwareAccounts: nil
				))
			)
		}

		return .none
	}

	private func importedOlympiaLedgerAccountsAndFactorSources(
		in state: inout State,
		ledgersWithAccounts: OrderedSet<ImportOlympiaLedgerAccountsAndFactorSources.LedgerWithAccounts>,
		unvalidated unvalidatedHardwareAccounts: Set<OlympiaAccountToMigrate>?
	) -> EffectTask<Action> {
		guard case let .migratedSoftwareAccounts(progress) = state.progress else { return progressError(state.progress) }

		let hardwareAccounts = IdentifiedArray(uniqueElements: ledgersWithAccounts.flatMap { $0.migratedAccounts.map(\.babylon) })

		state.path.append(
			.completion(.init(
				previouslyMigratedAccounts: progress.previouslyImported,
				migratedAccounts: progress.softwareAccounts + hardwareAccounts,
				unvalidatedOlympiaHardwareAccounts: unvalidatedHardwareAccounts
			))
		)

		return .none
	}

	private func progressError(_ progress: Progress, line: Int = #line) -> EffectTask<Action> {
		loggerGlobal.error("Implementation error. Incorrect progress value at line \(line): \(progress)")
		assertionFailure("Implementation error. Incorrect progress value at line \(line): \(progress)")
		return .send(.delegate(.dismiss))
	}
}

// MARK: - GotNoAccountsToImport
struct GotNoAccountsToImport: Error {}

// MARK: - OlympiaFactorSourceToSaveIDDisrepancy
struct OlympiaFactorSourceToSaveIDDisrepancy: Error {}
