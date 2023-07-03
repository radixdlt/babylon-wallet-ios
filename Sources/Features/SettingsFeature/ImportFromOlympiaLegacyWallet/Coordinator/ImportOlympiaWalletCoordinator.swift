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

	public struct MigratableAccount: Sendable, Hashable, Identifiable {
		public let id: K1.PublicKey
		public let accountName: String?
		public let olympiaAddress: LegacyOlympiaAccountAddress
		public let babylonAddress: AccountAddress
		public let appearanceID: Profile.Network.Account.AppearanceID
		public let olympiaAccountType: Olympia.AccountType
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
			let scannedAccounts: AccountsToMigrate
		}

		struct FoundAlreadyImported: Sendable, Hashable {
			let previous: ScannedQR
			let accountsToMigrate: AccountsToMigrate?
			let networkID: NetworkID
			let previouslyImported: [MigratableAccount]
		}

		struct CheckedIfOlympiaFactorSourceAlreadyExists: Sendable, Hashable {
			let previous: FoundAlreadyImported
			let softwareAccountsToMigrate: AccountsToMigrate
		}

		struct MigratedSoftwareAccounts: Sendable, Hashable {
			let previous: FoundAlreadyImported
			let migratedSoftwareAccounts: MigratedAccounts
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
			Set<OlympiaAccountToMigrate.ID>,
			existingAccounts: Int
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
		case finishedMigration(gotoAccountList: Bool)
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

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.engineToolkitClient) var engineToolkitClient
	@Dependency(\.dismiss) var dismiss
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
			return .run { _ in await dismiss() }
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
		case .accountsToImport(.delegate(.viewAppeared)):
			return accountsToImportViewAppeared(in: &state)

		case .accountsToImport(.delegate(.continueImport)):
			return continueImporting(in: &state)

		case let .importMnemonic(.delegate(.notSavedInProfile(mnemonicWithPassphrase))):
			return importedMnemonic(in: &state, mnemonicWithPassphrase: mnemonicWithPassphrase)

		case let .importOlympiaLedgerAccountsAndFactorSources(.delegate(.completed(migratedAccounts))):
			return importedOlympiaLedgerAccountsAndFactorSources(in: &state, migratedAccounts: migratedAccounts)

		case let .completion(.delegate(.finishedMigration(gotoAccountList: gotoAccountList))):
			return .send(.delegate(.finishedMigration(gotoAccountList: gotoAccountList)))

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .foundAlreadyImportedOlympiaSoftwareAccounts(networkID, alreadyImported, existingAccounts):
			return foundAlreadyImportedAccounts(in: &state, networkID: networkID, alreadyImported: alreadyImported, existingAccounts: existingAccounts)

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
		state.progress = .start
		state.scanQR.reset()
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
			scannedAccounts: scanned
		))

		return .task {
			let alreadyImported = await importLegacyWalletClient.findAlreadyImportedIfAny(scanned)
			let networkID = await factorSourcesClient.getCurrentNetworkID()
			let existingAccounts = await (try? accountsClient.getAccountsOnNetwork(networkID).count) ?? 0
			return .internal(.foundAlreadyImportedOlympiaSoftwareAccounts(networkID, alreadyImported, existingAccounts: existingAccounts))
		}
	}

	private func foundAlreadyImportedAccounts(
		in state: inout State,
		networkID: NetworkID,
		alreadyImported: Set<OlympiaAccountToMigrate.ID>,
		existingAccounts: Int
	) -> EffectTask<Action> {
		guard case let .scannedQR(progress) = state.progress else { return progressError(state.progress) }

		let scannedAccounts: NonEmptyArray<MigratableAccount>
		do {
			scannedAccounts = try migratableAccounts(from: progress.scannedAccounts, networkID: networkID, existingAccounts: existingAccounts)
		} catch {
			errorQueue.schedule(error)
			return generalError(error)
		}

		// These collections have different elements, the alreadyMigrated one keeps track of the babylon address
		let alreadyMigrated = scannedAccounts.rawValue.filter { alreadyImported.contains($0.id) }
		let notMigrated = progress.scannedAccounts.filter { !alreadyImported.contains($0.id) }

		state.progress = .foundAlreadyImported(.init(
			previous: progress,
			accountsToMigrate: NonEmpty(rawValue: OrderedSet(notMigrated)),
			networkID: networkID,
			previouslyImported: alreadyMigrated
		))

		state.path.append(
			.accountsToImport(.init(
				scannedAccounts: scannedAccounts
			))
		)
		return .none
	}

	private func accountsToImportViewAppeared(
		in state: inout State
	) -> EffectTask<Action> {
		// This happens if the user steps back from ImportMnemonic to AccountsToImport
		if case let .checkedIfOlympiaFactorSourceAlreadyExists(progress) = state.progress {
			state.progress = .foundAlreadyImported(progress.previous)
		}
		return .none
	}

	private func continueImporting(
		in state: inout State
	) -> EffectTask<Action> {
		guard case let .foundAlreadyImported(progress) = state.progress else { return progressError(state.progress) }

		if let softwareAccounts = progress.accountsToMigrate?.software {
			return checkIfOlympiaFactorSourceAlreadyExists(softwareAccounts)
		}

		state.progress = .migratedSoftwareAccounts(.init(
			previous: progress,
			migratedSoftwareAccounts: []
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
			previous: progress,
			softwareAccountsToMigrate: softwareAccounts
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
				header: .init(
					title: L10n.ImportOlympiaAccounts.VerifySeedPhrase.title,
					subtitle: L10n.ImportOlympiaAccounts.VerifySeedPhrase.subtitle
				),
				warning: L10n.ImportOlympiaAccounts.VerifySeedPhrase.warning,
				isWordCountFixed: true,
				persistAsMnemonicKind: nil,
				wordCount: progress.previous.expectedMnemonicWordCount
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
			previous: progress.previous,
			migratedSoftwareAccounts: softwareAccounts.babylonAccounts.rawValue
		))

		return migrateHardwareAccounts(in: &state)
	}

	private func migrateHardwareAccounts(
		in state: inout State
	) -> EffectTask<Action> {
		guard case let .migratedSoftwareAccounts(progress) = state.progress else { return progressError(state.progress) }

		if let hardwareAccounts = progress.previous.accountsToMigrate?.hardware {
			state.path.append(
				.importOlympiaLedgerAccountsAndFactorSources(.init(
					hardwareAccounts: hardwareAccounts,
					networkID: progress.previous.networkID
				))
			)
		} else {
			state.path.append(
				.completion(.init(
					previouslyMigrated: progress.previous.previouslyImported,
					migrated: progress.migratedSoftwareAccounts
				))
			)
		}

		return .none
	}

	private func importedOlympiaLedgerAccountsAndFactorSources(
		in state: inout State,
		migratedAccounts: MigratedAccounts
	) -> EffectTask<Action> {
		guard case let .migratedSoftwareAccounts(progress) = state.progress else { return progressError(state.progress) }

		state.path.append(
			.completion(.init(
				previouslyMigrated: progress.previous.previouslyImported,
				migrated: progress.migratedSoftwareAccounts + migratedAccounts
			))
		)

		return .none
	}
}

// MARK: - Helper methods

extension ImportOlympiaWalletCoordinator {
	private func migratableAccounts(
		from scannedAccounts: AccountsToMigrate,
		networkID: NetworkID,
		existingAccounts: Int
	) throws -> NonEmpty<[MigratableAccount]> {
		let result = try scannedAccounts.enumerated().map { index, account in
			let derivedAddress = try engineToolkitClient.deriveVirtualAccountAddress(.init(
				publicKey: .ecdsaSecp256k1(account.publicKey.intoEngine()),
				networkId: networkID
			))

			let babylonAddress = try AccountAddress(componentAddress: derivedAddress)

			return MigratableAccount(
				id: account.id,
				accountName: account.displayName?.rawValue,
				olympiaAddress: account.address,
				babylonAddress: babylonAddress,
				appearanceID: .fromIndex(existingAccounts + index),
				olympiaAccountType: account.accountType
			)
		}

		guard let nonEmpty = NonEmpty<[MigratableAccount]>(result) else {
			assertionFailure("This is impossible")
			struct ImpossibleError: Error {}
			throw ImpossibleError()
		}

		return nonEmpty
	}

	private func progressError(_ progress: Progress, line: Int = #line) -> EffectTask<Action> {
		loggerGlobal.error("Implementation error. Incorrect progress value at line \(line): \(progress)")
		assertionFailure("Implementation error. Incorrect progress value at line \(line): \(progress)")
		return .run { _ in await dismiss() }
	}

	private func generalError(_ error: Error) -> EffectTask<Action> {
		loggerGlobal.error("ImportOlympiaWalletCoordinator failed with error: \(error)")
		errorQueue.schedule(error)
		return .run { _ in await dismiss() }
	}
}

// MARK: - GotNoAccountsToImport
struct GotNoAccountsToImport: Error {}

// MARK: - OlympiaFactorSourceToSaveIDDisrepancy
struct OlympiaFactorSourceToSaveIDDisrepancy: Error {}

extension Collection<OlympiaAccountToMigrate> {
	var software: ImportOlympiaWalletCoordinator.AccountsToMigrate? {
		NonEmpty(rawValue: OrderedSet(filter { $0.accountType == .software }))
	}

	var hardware: ImportOlympiaWalletCoordinator.AccountsToMigrate? {
		NonEmpty(rawValue: OrderedSet(filter { $0.accountType == .hardware }))
	}
}
