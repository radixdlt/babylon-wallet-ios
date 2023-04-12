import AddLedgerNanoFactorSourceFeature
import Cryptography
import FactorSourcesClient
import FeaturePrelude
import ImportLegacyWalletClient
import Profile

// MARK: - ImportOlympiaWalletCoordinator
public struct ImportOlympiaWalletCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var expectedMnemonicWordCount: BIP39.WordCount?
		public var selectedAccounts: OlympiaAccountsToImport?
		public var mnemonicWithPassphrase: MnemonicWithPassphrase?
		public var migratedAccounts: IdentifiedArrayOf<Profile.Network.Account> = .init()

		var root: Destinations.State?
		var path: StackState<Destinations.State> = []

		public init() {
			self.root = .scanMultipleOlympiaQRCodes(.init())
		}
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case scanMultipleOlympiaQRCodes(ScanMultipleOlympiaQRCodes.State)
			case selectAccountsToImport(SelectAccountsToImport.State)
			case importOlympiaMnemonic(ImportOlympiaFactorSource.State)
			case addLedgerNanoFactorSource(AddLedgerNanoFactorSource.State)
			case validateOlympiaHardwareAccounts(ValidateOlympiaHardwareAccounts.State)
			case completion(CompletionMigrateOlympiaAccountsToBabylon.State)
		}

		public enum Action: Sendable, Equatable {
			case scanMultipleOlympiaQRCodes(ScanMultipleOlympiaQRCodes.Action)
			case selectAccountsToImport(SelectAccountsToImport.Action)
			case importOlympiaMnemonic(ImportOlympiaFactorSource.Action)
			case addLedgerNanoFactorSource(AddLedgerNanoFactorSource.Action)
			case validateOlympiaHardwareAccounts(ValidateOlympiaHardwareAccounts.Action)
			case completion(CompletionMigrateOlympiaAccountsToBabylon.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.scanMultipleOlympiaQRCodes, action: /Action.scanMultipleOlympiaQRCodes) {
				ScanMultipleOlympiaQRCodes()
			}
			Scope(state: /State.selectAccountsToImport, action: /Action.selectAccountsToImport) {
				SelectAccountsToImport()
			}
			Scope(state: /State.importOlympiaMnemonic, action: /Action.importOlympiaMnemonic) {
				ImportOlympiaFactorSource()
			}
			Scope(state: /State.addLedgerNanoFactorSource, action: /Action.addLedgerNanoFactorSource) {
				AddLedgerNanoFactorSource()
			}
			Scope(state: /State.validateOlympiaHardwareAccounts, action: /Action.validateOlympiaHardwareAccounts) {
				ValidateOlympiaHardwareAccounts()
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
		case path(StackAction<Destinations.Action>)
	}

	public enum InternalAction: Sendable, Equatable {
		case findAlreadyImportedOlympiaSoftwareAccounts(
			scanned: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
			alreadyImported: Set<OlympiaAccountToMigrate.ID>
		)

		case validatedOlympiaSoftwareAccounts(
			softwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
			privateHDFactorSource: PrivateHDFactorSource
		)
		case migratedOlympiaSoftwareAccounts(MigratedSoftwareAccounts)
		case migratedOlympiaHardwareAccounts(MigratedHardwareAccounts)
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

			if accounts.software != nil {
				let expectedWordCount: BIP39.WordCount = {
					if let expectedMnemonicWordCount = state.expectedMnemonicWordCount {
						return expectedMnemonicWordCount
					}
					assertionFailure("Expected to have set 'expectedMnemonicWordCount'")
					return .twelve
				}()

				let destination = Destinations.State.importOlympiaMnemonic(.init(
					shouldPersist: false,
					expectedWordCount: expectedWordCount,
					selectedAccounts: accounts.software
				))

				if state.path.last != destination {
					state.path.append(destination)
				}
			} else if accounts.hardware != nil {
				let destination = Destinations.State.addLedgerNanoFactorSource(.init())
				if state.path.last != destination {
					state.path.append(destination)
				}
			}

			return .none

		case let .path(.element(_, action: .importOlympiaMnemonic(.delegate(.alreadyExists(factorSourceID))))):
			guard let softwareAccounts = state.selectedAccounts?.software else {
				assertionFailure("Bad implementation, expected 'state.selectedAccounts.software' to have been set.")
				return .none
			}
			return convertToBabylon(
				softwareAccounts: softwareAccounts,
				factorSourceID: factorSourceID,
				factorSource: nil
			)

		case let .path(.element(_, action: .importOlympiaMnemonic(.delegate(.notPersisted(mnemonicWithPassphrase))))):
			state.mnemonicWithPassphrase = mnemonicWithPassphrase
			guard let softwareAccounts = state.selectedAccounts?.software else {
				assertionFailure("Bad implementation, expected 'state.selectedAccounts.software' to have been set.")
				return .none
			}
			return validateSoftwareAccounts(mnemonicWithPassphrase, softwareAccounts: softwareAccounts)

		case let .path(.element(_, action: .addLedgerNanoFactorSource(.delegate(.completed(ledgerFactorSourceID))))):
			guard let hardwareAccounts = state.selectedAccounts?.hardware else {
				assertionFailure("Bad implementation, expected 'state.selectedAccounts.hardware' to have been set.")
				return .none
			}
			let destination = Destinations.State.validateOlympiaHardwareAccounts(.init(
				hardwareAccounts: hardwareAccounts,
				ledgerNanoFactorSourceID: ledgerFactorSourceID
			))
			if state.path.last != destination {
				state.path.append(destination)
			}
			return .none

		case let .path(.element(_, action: .validateOlympiaHardwareAccounts(.delegate(.finishedVerifyingAccounts(validatedHardwareAccounts, ledgerNanoFactorSourceID))))):

			return convertToBabylon(
				hardwareAccounts: validatedHardwareAccounts,
				ledgerNanoFactorSourceID: ledgerNanoFactorSourceID
			)

		case .path(.element(_, action: .completion(.delegate(.finishedMigration)))):
			return .send(.delegate(.finishedMigration))
		default: return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
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

			return convertToBabylon(
				softwareAccounts: softwareAccounts,
				factorSourceID: privateHDFactorSource.id,
				factorSource: privateHDFactorSource
			)

		case let .migratedOlympiaSoftwareAccounts(migratedSoftwareAccounts):

			if state.selectedAccounts?.hardware != nil {
				state.migratedAccounts.append(contentsOf: migratedSoftwareAccounts.babylonAccounts.rawValue)
				// also need to add ledger and then migrate hardware account
				let destination = Destinations.State.addLedgerNanoFactorSource(.init())
				if state.path.last != destination {
					state.path.append(destination)
				}
			} else {
				assert(state.selectedAccounts?.hardware == nil)
				// no hardware accounts to migrate...
				let destination = Destinations.State.completion(.init(migratedAccounts: migratedSoftwareAccounts.babylonAccounts))
				if state.path.last != destination {
					state.path.append(destination)
				}
			}
			return .none
		case let .migratedOlympiaHardwareAccounts(migratedHardwareAccounts):
			state.migratedAccounts.append(contentsOf: migratedHardwareAccounts.babylonAccounts.rawValue)
			guard let migratedAccounts = Profile.Network.Accounts(rawValue: state.migratedAccounts) else {
				fatalError("bad!")
			}
			let destination = Destinations.State.completion(.init(migratedAccounts: migratedAccounts))
			if state.path.last != destination {
				state.path.append(destination)
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
				hdOnDeviceFactorSource: FactorSource.olympia(mnemonicWithPassphrase: mnemonicWithPassphrase)
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

	private func convertToBabylon(
		hardwareAccounts olympiaAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
		ledgerNanoFactorSourceID: FactorSourceID
	) -> EffectTask<Action> {
		.run { send in
			// Migrates and saved all accounts to Profile
			let migrated = try await importLegacyWalletClient.migrateOlympiaHardwareAccountsToBabylon(
				.init(
					olympiaAccounts: Set(olympiaAccounts.elements),
					ledgerFactorSourceID: ledgerNanoFactorSourceID
				)
			)
			await send(.internal(.migratedOlympiaHardwareAccounts(migrated)))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	private func convertToBabylon(
		softwareAccounts olympiaAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
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
				// We have not yet saved the factorSource, so lets do that
				guard try factorSourceToSave.id == FactorSource.id(fromPrivateHDFactorSource: factorSource) else {
					throw OlympiaFactorSourceToSaveIDDisrepancy()
				}

				do {
					_ = try await factorSourcesClient.addPrivateHDFactorSource(.init(
						mnemonicWithPassphrase: factorSource.mnemonicWithPassphrase,
						hdOnDeviceFactorSource: factorSourceToSave
					)
					)

				} catch {
					let msg = "Failed to save factor source (mnemonic) but have already created accounts, error: \(error)"
					loggerGlobal.critical(.init(stringLiteral: msg))
					assertionFailure(msg)
					errorQueue.schedule(error)
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
