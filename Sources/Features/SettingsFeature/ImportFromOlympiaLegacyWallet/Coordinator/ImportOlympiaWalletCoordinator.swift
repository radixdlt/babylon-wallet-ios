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

	public struct State: Sendable, Hashable {
		public var scanQR: ScanMultipleOlympiaQRCodes.State = .init()
		public var path: StackState<Path.State> = .init()

		var progress: Progress = .start

		public init() {}
	}

	enum Progress: Sendable, Hashable {
		case start
		case scannedQR(ScannedQR)
		case foundAlreadyImported(FoundAlreadyImported)
		case checkedIfOlympiaFactorSourceAlreadyExists(CheckedIfOlympiaFactorSourceAlreadyExists)

		case migratedSoftwareAccounts

		case migratedHardwareAccounts

		case importMnemonic
		case importOlympiaLedgerAccountsAndFactorSources
		case completion

		struct ScannedQR: Sendable, Hashable {
			let expectedMnemonicWordCount: BIP39.WordCount
			let scanned: AccountsToMigrate
		}

		struct FoundAlreadyImported: Sendable, Hashable {
			let expectedMnemonicWordCount: BIP39.WordCount
			let scanned: AccountsToMigrate
			let alreadyImported: Set<OlympiaAccountToMigrate.ID>
			let softwareAccounts: AccountsToMigrate?
			let hardwareAccounts: AccountsToMigrate?
		}

		struct CheckedIfOlympiaFactorSourceAlreadyExists: Sendable, Hashable {
			//			let expectedMnemonicWordCount: BIP39.WordCount
			//			let scanned: AccountsToMigrate
			//			let alreadyImported: Set<OlympiaAccountToMigrate.ID>
			let softwareAccounts: AccountsToMigrate
			//			let hardwareAccounts: AccountsToMigrate?
		}

		struct MigratedSoftwareAccounts: Sendable, Hashable {
			let expectedMnemonicWordCount: BIP39.WordCount
			let scanned: AccountsToMigrate
			let alreadyImported: Set<OlympiaAccountToMigrate.ID>
			let softwareAccounts: MigratedAccounts
			let hardwareAccounts: AccountsToMigrate?
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
			Set<OlympiaAccountToMigrate.ID>
		)
		case checkedIfOlympiaFactorSourceAlreadyExists(
			FactorSourceID.FromHash?,
			softwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
		)
		case validatedOlympiaSoftwareAccounts(
			softwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
			privateHDFactorSource: PrivateHDFactorSource
		)
		case migratedOlympiaSoftwareAccounts(
			MigratedSoftwareAccounts
		)
		case migrateHardwareAccounts(
			NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
			NetworkID
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

	private func finishedScanning(
		in state: inout State,
		olympiaWallet: ScannedParsedOlympiaWalletToMigrate
	) -> EffectTask<Action> {
		guard case .start = state.progress else { return .none }

		let scanned = olympiaWallet.accounts
		state.progress = .scannedQR(.init(
			expectedMnemonicWordCount: olympiaWallet.mnemonicWordCount,
			scanned: scanned
		))

		return findAlreadyImportedAccounts(scanned: scanned)
	}

	private func findAlreadyImportedAccounts(
		scanned: AccountsToMigrate
	) -> EffectTask<Action> {
		.task {
			let alreadyImported = await importLegacyWalletClient.findAlreadyImportedIfAny(scanned)
			return .internal(.foundAlreadyImportedOlympiaSoftwareAccounts(alreadyImported))
		}
	}

	private func foundAlreadyImportedAccounts(
		in state: inout State,
		alreadyImported: Set<OlympiaAccountToMigrate.ID>
	) -> EffectTask<Action> {
		guard case let .scannedQR(progress) = state.progress else { return .none }

		let notImported = progress.scanned.filter { !alreadyImported.contains($0.id) }
		let softwareAccounts = NonEmpty(rawValue: OrderedSet(notImported.filter { $0.accountType == .software }))
		let hardwareAccounts = NonEmpty(rawValue: OrderedSet(notImported.filter { $0.accountType == .hardware }))

		state.progress = .foundAlreadyImported(.init(
			expectedMnemonicWordCount: progress.expectedMnemonicWordCount,
			scanned: progress.scanned,
			alreadyImported: alreadyImported,
			softwareAccounts: softwareAccounts,
			hardwareAccounts: hardwareAccounts
		))
		state.path.append(
			.accountsToImport(.init(scannedAccounts: progress.scanned))
		)

		return .none
	}

	private func continueImporting(
		in state: inout State
	) -> EffectTask<Action> {
		guard case let .foundAlreadyImported(progress) = state.progress else { return .none }

		if let softwareAccounts = progress.softwareAccounts {
			return migrateSoftwareAccounts(softwareAccounts)
		} else if let hardwareAccounts = progress.hardwareAccounts {
			return migrateHardwareAccounts(hardwareAccounts)
		} else {
			return complete(in: &state)
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

	private func checkedIfOlympiaFactorSourceAlreadyExists(
		in state: inout State,
		idOfExistingFactorSource: FactorSourceID.FromHash?,
		softwareAccounts: AccountsToMigrate
	) -> EffectTask<Action> {
		guard case let .foundAlreadyImported(progress) = state.progress else { return .none }

		state.progress = .checkedIfOlympiaFactorSourceAlreadyExists(.init(softwareAccounts: softwareAccounts))

		guard let idOfExistingFactorSource else {
			state.path.append(
				.importMnemonic(.init(
					persistAsMnemonicKind: nil,
					wordCount: progress.expectedMnemonicWordCount
				))
			)

			return .none
		}
		return convertSoftwareAccountsToBabylon(
			softwareAccounts,
			factorSourceID: idOfExistingFactorSource,
			factorSource: nil
		)

		//	return validateSoftwareAccounts(mnemonicWithPassphrase, softwareAccounts: progress.softwareAccounts)
	}

	private func importedMnemonic(
		in state: inout State,
		mnemonicWithPassphrase: MnemonicWithPassphrase
	) -> EffectTask<Action> {
		guard case let .checkedIfOlympiaFactorSourceAlreadyExists(progress) = state.progress else { return .none }
		return validateSoftwareAccounts(mnemonicWithPassphrase, softwareAccounts: progress.softwareAccounts)
	}

	public func complete(in state: inout State) -> EffectTask<Action> {
		//				state.path.append(
		//					.completion(.init(migratedAccounts: T##Profile.Network.Accounts,
		//									  unvalidatedOlympiaHardwareAccounts: <#T##Set<OlympiaAccountToMigrate>?#>))
		//				)
		.none
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

			//				.checkedIfOlympiaFactorSourceAlreadyExists(progress)
			return validateSoftwareAccounts(mnemonicWithPassphrase, softwareAccounts: progress.softwareAccounts)

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
		switch internalAction {
		case let .foundAlreadyImportedOlympiaSoftwareAccounts(alreadyImported):
			return foundAlreadyImportedAccounts(in: &state, alreadyImported: alreadyImported)

		case let (.checkedIfOlympiaFactorSourceAlreadyExists(idOfExistingFactorSource, softwareAccounts),
		          .foundAlreadyImported(scanned, expectedMnemonicWordCount, _, _, _)):
//			state.progress = .checkedIfOlympiaFactorSourceAlreadyExists(softwareAccounts: softwareAccounts)
//
//			guard let idOfExistingFactorSource else {
//				state.path.append(
//					.importMnemonic(.init(
//						persistAsMnemonicKind: nil,
//						wordCount: expectedMnemonicWordCount
//					))
//				)
//
//				return .none
//			}
//			return convertSoftwareAccountsToBabylon(
//				softwareAccounts,
//				factorSourceID: idOfExistingFactorSource,
//				factorSource: nil
//			)

		case let (.migratedOlympiaSoftwareAccounts(migratedSoftwareAccounts),
		          _):

			// progress: 		migrated: MigratedSoftwareAccounts
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

		case let (.migrateHardwareAccounts(hardwareAccounts, networkID),
		          _):
			let destination: Path.State = .importOlympiaLedgerAccountsAndFactorSources(.init(
				hardwareAccounts: hardwareAccounts,
				networkID: networkID
			))
			if state.path.last != destination {
				state.path.append(destination)
			}
			return .none

		default:
			let msg = "Implementation error, can't accept \(internalAction) with progress \(state.progress)"
			loggerGlobal.critical(.init(stringLiteral: msg))
			assertionFailure(msg)
			return .none
		}
	}
}

extension ImportOlympiaWalletCoordinator {
	private func validateSoftwareAccounts(
		_ mnemonicWithPassphrase: MnemonicWithPassphrase,
		softwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
	) -> EffectTask<Action> {
		do {
			try mnemonicWithPassphrase.validatePublicKeysOf(
				softwareAccounts: softwareAccounts
			)

			let privateHDFactorSource = try PrivateHDFactorSource(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				factorSource: DeviceFactorSource.olympia(mnemonicWithPassphrase: mnemonicWithPassphrase)
			)

			return convertSoftwareAccountsToBabylon(
				softwareAccounts,
				factorSourceID: privateHDFactorSource.factorSource.id,
				factorSource: privateHDFactorSource
			)
		} catch {
			errorQueue.schedule(error)
			return .none
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

	private func migrateHardwareAccounts(
		_ hardwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
	) -> EffectTask<Action> {
		.task {
			let networkID = await factorSourcesClient.getCurrentNetworkID()
			return .internal(.migrateHardwareAccounts(hardwareAccounts, networkID))
		}
	}
}

// MARK: - GotNoAccountsToImport
struct GotNoAccountsToImport: Error {}

// MARK: - OlympiaFactorSourceToSaveIDDisrepancy
struct OlympiaFactorSourceToSaveIDDisrepancy: Error {}
