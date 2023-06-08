import Cryptography
import FactorSourcesClient
import FeaturePrelude
import ImportLegacyWalletClient
import ImportMnemonicFeature
import ImportOlympiaLedgerAccountsAndFactorSourcesFeature
import Profile

// MARK: - ImportOlympiaWalletCoordinator
public struct ImportOlympiaWalletCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var expectedMnemonicWordCount: BIP39.WordCount?
		public var selectedAccounts: OlympiaAccountsToImport?
		public var mnemonicWithPassphrase: MnemonicWithPassphrase?
		public var migratedAccounts: IdentifiedArrayOf<Profile.Network.Account> = .init()

		var root: Destinations.State?
		var path: StackState<Destinations.State> = .init()

		public init() {
			self.root = .scanMultipleOlympiaQRCodes(.init())
		}
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case scanMultipleOlympiaQRCodes(ScanMultipleOlympiaQRCodes.State)
			case selectAccountsToImport(SelectAccountsToImport.State)
			case importMnemonic(ImportMnemonic.State)
			case importOlympiaLedgerAccountsAndFactorSources(ImportOlympiaLedgerAccountsAndFactorSources.State)
			case completion(CompletionMigrateOlympiaAccountsToBabylon.State)
		}

		public enum Action: Sendable, Equatable {
			case scanMultipleOlympiaQRCodes(ScanMultipleOlympiaQRCodes.Action)
			case selectAccountsToImport(SelectAccountsToImport.Action)
			case importMnemonic(ImportMnemonic.Action)
			case importOlympiaLedgerAccountsAndFactorSources(ImportOlympiaLedgerAccountsAndFactorSources.Action)
			case completion(CompletionMigrateOlympiaAccountsToBabylon.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.scanMultipleOlympiaQRCodes, action: /Action.scanMultipleOlympiaQRCodes) {
				ScanMultipleOlympiaQRCodes()
			}
			Scope(state: /State.selectAccountsToImport, action: /Action.selectAccountsToImport) {
				SelectAccountsToImport()
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
		case root(Destinations.Action)
		case path(StackActionOf<Destinations>)
	}

	public enum InternalAction: Sendable, Equatable {
		case findAlreadyImportedOlympiaSoftwareAccounts(
			scanned: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
			alreadyImported: Set<OlympiaAccountToMigrate.ID>
		)
		case checkedIfOlympiaFactorSourceAlreadyExists(FactorSourceID?)

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
		Reduce(core)
			.ifLet(\.root, action: /Action.child .. ChildAction.root) {
				Destinations()
			}
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .send(.delegate(.dismiss))
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

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .root(.scanMultipleOlympiaQRCodes(.delegate(.finishedScanning(olympiaWallet)))):
			state.expectedMnemonicWordCount = olympiaWallet.mnemonicWordCount
			let scanned = olympiaWallet.accounts
			return .run { send in

				let alreadyImported = await importLegacyWalletClient.findAlreadyImportedIfAny(scanned)

				await send(.internal(.findAlreadyImportedOlympiaSoftwareAccounts(
					scanned: scanned,
					alreadyImported: alreadyImported
				)))
			}

		case let .path(.element(_, action: .selectAccountsToImport(.delegate(.selectedAccounts(accounts))))):
			state.selectedAccounts = accounts

			if let softwareAccounts = accounts.software {
				return .run { send in
					let idOfExistingFactorSource = await factorSourcesClient
						.checkIfHasOlympiaFactorSourceForAccounts(softwareAccounts)

					await send(.internal(.checkedIfOlympiaFactorSourceAlreadyExists(idOfExistingFactorSource)))
				}
			} else if let hardwareAccounts = accounts.hardware {
				return migrateHardwareAccounts(hardwareAccounts)
			}

			return .none

		case let .path(.element(_, action: .importMnemonic(.delegate(.notSavedInProfile(mnemonicWithPassphrase))))):
			state.mnemonicWithPassphrase = mnemonicWithPassphrase
			guard let softwareAccounts = state.selectedAccounts?.software else {
				assertionFailure("Bad implementation, expected 'state.selectedAccounts.software' to have been set.")
				return .none
			}
			return validateSoftwareAccounts(mnemonicWithPassphrase, softwareAccounts: softwareAccounts)

		case let .path(.element(_, action: .importOlympiaLedgerAccountsAndFactorSources(.delegate(
			.completed(ledgersWithAccounts, unvalidatedOlympiaAccounts)
		)))):
			loggerGlobal.notice("Coordinator, proceeding to completion")
			state.migratedAccounts.append(contentsOf: ledgersWithAccounts.flatMap { $0.migratedAccounts.map(\.babylon) })

			guard let migratedAccounts = Profile.Network.Accounts(rawValue: state.migratedAccounts) else {
				fatalError("bad!")
			}
			let destination = Destinations.State.completion(.init(migratedAccounts: migratedAccounts, unvalidatedOlympiaHardwareAccounts: unvalidatedOlympiaAccounts))
			if state.path.last != destination {
				state.path.append(destination)
			}
			return .none

		case .path(.element(_, action: .completion(.delegate(.finishedMigration)))):
			return .send(.delegate(.finishedMigration))
		default: return .none
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

				let destination = Destinations.State.importMnemonic(.init(
					persistAsMnemonicKind: nil,
					wordCount: expectedWordCount
				))

				if state.path.last != destination {
					state.path.append(destination)
				}
				return .none
			}
			guard let softwareAccounts = state.selectedAccounts?.software else {
				assertionFailure("Bad implementation, expected 'state.selectedAccounts.software' to have been set.")
				return .none
			}
			return convertSoftwareAccountsToBabylon(
				softwareAccounts,
				factorSourceID: idOfExistingFactorSource,
				factorSource: nil
			)

		case let .migrateHardwareAccounts(hardwareAccounts, networkID):
			let destination = Destinations.State.importOlympiaLedgerAccountsAndFactorSources(.init(
				hardwareAccounts: hardwareAccounts,
				networkID: networkID
			))
			if state.path.last != destination {
				state.path.append(destination)
			}
			return .none

		case let .findAlreadyImportedOlympiaSoftwareAccounts(scanned, alreadyImported):
			let destination = Destinations.State.selectAccountsToImport(.init(
				scannedAccounts: scanned,
				alreadyImported: alreadyImported
			))

			if state.path.last != destination {
				state.path.append(destination)
			}
			return .none

		case let .validatedOlympiaSoftwareAccounts(softwareAccounts, privateHDFactorSource):

			return convertSoftwareAccountsToBabylon(
				softwareAccounts,
				factorSourceID: privateHDFactorSource.factorSource.id,
				factorSource: privateHDFactorSource
			)

		case let .migratedOlympiaSoftwareAccounts(migratedSoftwareAccounts):

			if let hardwareAccounts = state.selectedAccounts?.hardware {
				state.migratedAccounts.append(contentsOf: migratedSoftwareAccounts.babylonAccounts.rawValue)
				// also need to add ledger and then migrate hardware account
				return migrateHardwareAccounts(hardwareAccounts)
			} else {
				assert(state.selectedAccounts?.hardware == nil)
				// no hardware accounts to migrate...
				let destination = Destinations.State.completion(.init(migratedAccounts: migratedSoftwareAccounts.babylonAccounts, unvalidatedOlympiaHardwareAccounts: nil))
				if state.path.last != destination {
					state.path.append(destination)
				}
			}
			return .none
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
		factorSourceID: FactorSourceID,
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
					if let existing = try await factorSourcesClient.getFactorSource(id: factorSourceToSave.id) {
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
struct GotNoAccountsToImport: Swift.Error {}

// MARK: - OlympiaFactorSourceToSaveIDDisrepancy
struct OlympiaFactorSourceToSaveIDDisrepancy: Swift.Error {}
