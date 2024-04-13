import ComposableArchitecture
import SwiftUI

// MARK: - ImportOlympiaWalletCoordinator
public struct ImportOlympiaWalletCoordinator: Sendable, FeatureReducer {
	public typealias AccountsToMigrate = NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
	public typealias MigratedAccounts = IdentifiedArrayOf<Sargon.Account>

	// MARK: State

	public struct State: Sendable, Hashable {
		public var scanQR: ScanMultipleOlympiaQRCodes.State = .init()
		public var path: StackState<Path.State> = .init()

		var progress: Progress = .start

		public init() {}
	}

	public struct MigratableAccount: Sendable, Hashable, Identifiable {
		public let id: Secp256k1PublicKey
		public let accountName: String?
		public let olympiaAddress: LegacyOlympiaAccountAddress
		public let babylonAddress: AccountAddress
		public let appearanceID: AppearanceID
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

		enum Discriminator: String {
			case start
			case scannedQR
			case foundAlreadyImported
			case checkedIfOlympiaFactorSourceAlreadyExists
			case migratedSoftwareAccounts
			case completion
		}

		var discriminator: Discriminator {
			switch self {
			case .start: .start
			case .scannedQR: .scannedQR
			case .foundAlreadyImported: .foundAlreadyImported
			case .checkedIfOlympiaFactorSourceAlreadyExists: .checkedIfOlympiaFactorSourceAlreadyExists
			case .migratedSoftwareAccounts: .migratedSoftwareAccounts
			case .completion: .completion
			}
		}

		struct ScannedQR: Sendable, Hashable {
			let expectedMnemonicWordCount: BIP39WordCount
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
			FactorSourceIDFromHash?,
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

	public struct Path: Sendable, Reducer {
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

		public var body: some ReducerOf<Self> {
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
	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.importLegacyWalletClient) var importLegacyWalletClient
	@Dependency(\.userDefaults) var userDefaults
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.secureStorageClient) var secureStorageClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.scanQR, action: /Action.child .. ChildAction.scanQR) {
			ScanMultipleOlympiaQRCodes()
		}
		Reduce(core)
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			.run { _ in await dismiss() }
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .scanQR(.delegate(.viewAppeared)):
			scanViewAppeared(in: &state)

		case let .scanQR(.delegate(.finishedScanning(olympiaWallet))):
			finishedScanning(in: &state, olympiaWallet: olympiaWallet)

		case let .path(.element(_, action: pathAction)):
			reduce(into: &state, pathAction: pathAction)

		default:
			.none
		}
	}

	public func reduce(into state: inout State, pathAction: Path.Action) -> Effect<Action> {
		switch pathAction {
		case .accountsToImport(.delegate(.viewAppeared)):
			return accountsToImportViewAppeared(in: &state)

		case .accountsToImport(.delegate(.continueImport)):
			return continueImporting(in: &state)

		case let .importMnemonic(.delegate(.notPersisted(mnemonicWithPassphrase))):
			return importedMnemonic(in: &state, mnemonicWithPassphrase: mnemonicWithPassphrase)

		case .importMnemonic(.delegate(.persistedMnemonicInKeychainOnly)), .importMnemonic(.delegate(.doneViewing)), .importMnemonic(.delegate(.persistedNewFactorSourceInProfile)):
			preconditionFailure("Incorrect implementation")
			return .none

		case let .importOlympiaLedgerAccountsAndFactorSources(.delegate(.completed(migratedAccounts))):
			return importedOlympiaLedgerAccountsAndFactorSources(in: &state, migratedAccounts: migratedAccounts)

		case let .importOlympiaLedgerAccountsAndFactorSources(.delegate(.failed(failure))):
			return cancelOlympiaLedgerAccountsAndFactorSources(in: &state, failure: failure)

		case let .completion(.delegate(.finishedMigration(gotoAccountList: gotoAccountList))):
			return .send(.delegate(.finishedMigration(gotoAccountList: gotoAccountList)))

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .foundAlreadyImportedOlympiaSoftwareAccounts(networkID, alreadyImported, existingAccounts):
			foundAlreadyImportedAccounts(
				in: &state,
				networkID: networkID,
				alreadyImported: alreadyImported,
				existingAccounts: existingAccounts
			)

		case let .checkedIfOlympiaFactorSourceAlreadyExists(idOfExistingFactorSource, softwareAccounts):
			checkedIfOlympiaFactorSourceAlreadyExists(
				in: &state,
				idOfExistingFactorSource: idOfExistingFactorSource,
				softwareAccounts: softwareAccounts
			)

		case let .migratedSoftwareAccountsToBabylon(softwareAccounts):
			migratedSoftwareAccountsToBabylon(in: &state, softwareAccounts: softwareAccounts)
		}
	}

	// MARK: Main logic

	private func scanViewAppeared(
		in state: inout State
	) -> Effect<Action> {
		state.progress = .start
		state.scanQR.reset()
		return .none
	}

	private func finishedScanning(
		in state: inout State,
		olympiaWallet: ScannedParsedOlympiaWalletToMigrate
	) -> Effect<Action> {
		guard case .start = state.progress else { return progressError(state.progress) }

		let scanned = olympiaWallet.accounts
		state.progress = .scannedQR(.init(
			expectedMnemonicWordCount: olympiaWallet.mnemonicWordCount,
			scannedAccounts: scanned
		))

		return .run { send in
			let alreadyImported = await importLegacyWalletClient.findAlreadyImportedIfAny(scanned)
			let networkID = await factorSourcesClient.getCurrentNetworkID()
			let existingAccounts = await (try? accountsClient.getAccountsOnNetwork(networkID).count) ?? 0
			await send(.internal(.foundAlreadyImportedOlympiaSoftwareAccounts(networkID, alreadyImported, existingAccounts: existingAccounts)))
		}
	}

	private func foundAlreadyImportedAccounts(
		in state: inout State,
		networkID: NetworkID,
		alreadyImported: Set<OlympiaAccountToMigrate.ID>,
		existingAccounts: Int
	) -> Effect<Action> {
		guard case let .scannedQR(progress) = state.progress else { return progressError(state.progress) }

		let scannedAccounts: NonEmptyArray<MigratableAccount>
		do {
			scannedAccounts = try migratableAccounts(
				from: progress.scannedAccounts,
				networkID: networkID,
				existingAccounts: existingAccounts
			)
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
	) -> Effect<Action> {
		if case let .checkedIfOlympiaFactorSourceAlreadyExists(progress) = state.progress {
			// This happens if the user steps back from ImportMnemonic to AccountsToImport
			state.progress = .foundAlreadyImported(progress.previous)
		} else if case let .migratedSoftwareAccounts(progress) = state.progress {
			// This happens if the user steps back from ImportOlympiaLedgerAccountsAndFactorSources to AccountsToImport
			state.progress = .foundAlreadyImported(progress.previous)
		}
		return .none
	}

	private func continueImporting(
		in state: inout State
	) -> Effect<Action> {
		guard
			case let .foundAlreadyImported(progress) = state.progress
		else {
			return progressError(state.progress)
		}

		if let softwareAccounts = progress.accountsToMigrate?.software {
			return checkIfOlympiaFactorSourceAlreadyExists(wordCount: progress.previous.expectedMnemonicWordCount, softwareAccounts)
		}
		state.progress = .migratedSoftwareAccounts(.init(
			previous: progress,
			migratedSoftwareAccounts: []
		))

		return migrateHardwareAccounts(in: &state)
	}

	private func checkIfOlympiaFactorSourceAlreadyExists(
		wordCount: BIP39WordCount,
		_ softwareAccounts: AccountsToMigrate
	) -> Effect<Action> {
		.run { send in
			let idOfExistingFactorSource = await factorSourcesClient.checkIfHasOlympiaFactorSourceForAccounts(wordCount, softwareAccounts)
			await send(.internal(.checkedIfOlympiaFactorSourceAlreadyExists(idOfExistingFactorSource, softwareAccounts: softwareAccounts)))
		}
	}

	private func checkedIfOlympiaFactorSourceAlreadyExists(
		in state: inout State,
		idOfExistingFactorSource: FactorSourceIDFromHash?,
		softwareAccounts: AccountsToMigrate
	) -> Effect<Action> {
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
				warningOnContinue: .init(
					title: L10n.ImportOlympiaAccounts.VerifySeedPhrase.title,
					text: L10n.ImportOlympiaAccounts.VerifySeedPhrase.keepSeedPhrasePrompt,
					button: L10n.ImportOlympiaAccounts.VerifySeedPhrase.keepSeedPhrasePromptConfirmation
				),
				isWordCountFixed: true,
				persistStrategy: nil,
				wordCount: progress.previous.expectedMnemonicWordCount
			))
		)

		return .none
	}

	private func importedMnemonic(
		in state: inout State,
		mnemonicWithPassphrase: MnemonicWithPassphrase
	) -> Effect<Action> {
//		guard case let .checkedIfOlympiaFactorSourceAlreadyExists(progress) = state.progress else { return progressError(state.progress) }
//
//		do {
//			try mnemonicWithPassphrase.validatePublicKeys(
//				of: progress.softwareAccountsToMigrate
//			)
//
//			let privateHDFactorSource = try PrivateHierarchicalDeterministicFactorSource(
//				mnemonicWithPassphrase: mnemonicWithPassphrase,
//				factorSource: DeviceFactorSource.olympia(
//					mnemonicWithPassphrase: mnemonicWithPassphrase
//				)
//			)
//
//			return migrateSoftwareAccountsToBabylon(
//				progress.softwareAccountsToMigrate,
//				factorSourceID: privateHDFactorSource.factorSource.id,
//				factorSource: privateHDFactorSource
//			)
//		} catch {
//			errorQueue.schedule(error)
//			return .none
//		}
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	private func migrateSoftwareAccountsToBabylon(
		_ olympiaAccounts: AccountsToMigrate,
		factorSourceID: FactorSourceIDFromHash,
		factorSource: PrivateHierarchicalDeterministicFactorSource?
	) -> Effect<Action> {
		/*
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

		 		let existing = try? await factorSourcesClient.getFactorSource(id: factorSourceToSave.id.embed())
		 		do {
		 			let saveIntoProfile = existing == nil
		 			if saveIntoProfile {
		 				loggerGlobal.notice("Skip saving Olympia mnemonic into Profile since it is already present, will save to keychain only")
		 			}

		 			try await factorSourcesClient.addOnDeviceFactorSource(
		 				privateHDFactorSource: factorSource,
		 				// This is mega edge case, but if we were to use `.abort` here, then users
		 				// who used a 24 word mnemonic `M` with Olympia wallet and then created their
		 				// Babylon Wallet using Account Recovery Scan with `M` would not be able to
		 				// perform Olympia import.
		 				onMnemonicExistsStrategy: .appendWithCryptoParamaters,
		 				saveIntoProfile: saveIntoProfile
		 			)

		 			overlayWindowClient.scheduleHUD(.seedPhraseImported)

		 		} catch {
		 			loggerGlobal.critical("Failed to save Olympia Mnemonic - error: \(error)")

		 			// Check if we have already imported this Mnemonic
		 			if let existing {
		 				let presentInKeychain = secureStorageClient.containsMnemonicIdentifiedByFactorSourceID(factorSourceToSave.id)
		 				if existing.kind == .device, existing.supportsOlympia, presentInKeychain {
		 					// all good, we had already imported it.
		 					loggerGlobal.notice("We had already imported this factor source (mnemonic) before.")
		 				} else {
		 					let msg = "Failed to save factor source (mnemonic), found in Profile, exists in keychain? \(presentInKeychain). Maybe it is not of .device kind or does not support olympia params. error: \(error)"
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

		 	// Save all accounts
		 	try await accountsClient.saveVirtualAccounts(migrated.babylonAccounts.elements)

		 	do {
		 		try userDefaults.addFactorSourceIDOfBackedUpMnemonic(factorSourceID)
		 	} catch {
		 		// Not important enought to throw
		 		loggerGlobal.warning("Failed to save mnemonic as backed up, error: \(error)")
		 	}

		 	await send(.internal(.migratedSoftwareAccountsToBabylon(migrated)))
		 } catch: { error, _ in
		 	errorQueue.schedule(error)
		 }
		  */
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public func migratedSoftwareAccountsToBabylon(
		in state: inout State,
		softwareAccounts: MigratedSoftwareAccounts
	) -> Effect<Action> {
		/*
		 guard
		 	case let .checkedIfOlympiaFactorSourceAlreadyExists(progress) = state.progress
		 else {
		 	loggerGlobal.critical("Expected state to have been 'checkedIfOlympiaFactorSourceAlreadyExists' but it was: \(state.progress.discriminator)")
		 	return progressError(state.progress)
		 }

		 state.progress = .migratedSoftwareAccounts(.init(
		 	previous: progress.previous,
		 	migratedSoftwareAccounts: softwareAccounts.babylonAccounts
		 ))

		 return migrateHardwareAccounts(in: &state)
		  */
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	private func migrateHardwareAccounts(
		in state: inout State
	) -> Effect<Action> {
		guard case let .migratedSoftwareAccounts(progress) = state.progress else { return progressError(state.progress) }

		if let hardwareAccounts = progress.previous.accountsToMigrate?.hardware {
			state.path.append(
				.importOlympiaLedgerAccountsAndFactorSources(.init(
					networkID: progress.previous.networkID,
					hardwareAccounts: hardwareAccounts
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
	) -> Effect<Action> {
		guard case let .migratedSoftwareAccounts(progress) = state.progress else { return progressError(state.progress) }

		state.path.append(
			.completion(.init(
				previouslyMigrated: progress.previous.previouslyImported,
				migrated: progress.migratedSoftwareAccounts + migratedAccounts
			))
		)

		return .none
	}

	private func cancelOlympiaLedgerAccountsAndFactorSources(
		in state: inout State,
		failure: ImportOlympiaLedgerAccountsAndFactorSources.DelegateAction.Failure
	) -> Effect<Action> {
		guard case .migratedSoftwareAccounts = state.progress else { return progressError(state.progress) }

		return .run { _ in
			await dismiss()
		}
	}
}

// MARK: - Helper methods
extension ImportOlympiaWalletCoordinator {
	private func migratableAccounts(
		from scannedAccounts: AccountsToMigrate,
		networkID: NetworkID,
		existingAccounts: Int
	) throws -> NonEmpty<[MigratableAccount]> {
		/*
		 let result = scannedAccounts.enumerated().map { index, account in
		 	let babylonAddress = AccountAddress(
		 		publicKey: Sargon.PublicKey.ecdsaSecp256k1(account.publicKey).intoSargon(),
		 		networkID: networkID
		 	)

		 	return MigratableAccount(
		 		id: account.id,
		 		accountName: account.displayName?.rawValue,
		 		olympiaAddress: account.address,
		 		babylonAddress: babylonAddress,
		 		appearanceID: .fromNumberOfAccounts(existingAccounts + index),
		 		olympiaAccountType: account.accountType
		 	)
		 }

		 guard let nonEmpty = NonEmpty<[MigratableAccount]>(result) else {
		 	assertionFailure("This is impossible")
		 	struct ImpossibleError: Error {}
		 	throw ImpossibleError()
		 }

		 return nonEmpty
		  */
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	private func progressError(_ progress: Progress, line: Int = #line) -> Effect<Action> {
		loggerGlobal.error("Implementation error. Incorrect progress value at line \(line): \(progress)")
		assertionFailure("Implementation error. Incorrect progress value at line \(line): \(progress)")
		return .run { _ in await dismiss() }
	}

	private func generalError(_ error: Error) -> Effect<Action> {
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
