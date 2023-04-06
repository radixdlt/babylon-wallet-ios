import AccountsClient
import Cryptography
import FeaturePrelude
import Profile

// MARK: - ImportOlympiaWalletCoordinator
public struct ImportOlympiaWalletCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var expectedMnemonicWordCount: BIP39.WordCount?
		public var selectedAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>?
		public var mnemonicWithPassphrase: MnemonicWithPassphrase?

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
			case completion(CompletionMigrateOlympiaAccountsToBabylon.State)
		}

		public enum Action: Sendable, Equatable {
			case scanMultipleOlympiaQRCodes(ScanMultipleOlympiaQRCodes.Action)
			case selectAccountsToImport(SelectAccountsToImport.Action)
			case importOlympiaMnemonic(ImportOlympiaFactorSource.Action)
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
		case validated(
			olympiaAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
			privateHDFactorSource: PrivateHDFactorSource
		)
		case migratedAccounts(MigratedAccounts)
	}

	public enum DelegateAction: Sendable, Equatable {
		case finishedMigration
		case dismiss
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient
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
		case let .root(Destinations.Action.scanMultipleOlympiaQRCodes(.delegate(.finishedScanning(olympiaWallet)))):
			state.expectedMnemonicWordCount = olympiaWallet.mnemonicWordCount
			let destination = Destinations.State.selectAccountsToImport(.init(scannedAccounts: olympiaWallet.accounts))
			if state.path.last != destination {
				state.path.append(destination)
			}
			return .none
		case let .path(.element(_, action: .selectAccountsToImport(.delegate(.selectedAccounts(accounts))))):
			state.selectedAccounts = accounts
			let destination = Destinations.State.importOlympiaMnemonic(.init(shouldPersist: false))
			if state.path.last != destination {
				state.path.append(destination)
			}
			return .none
		case let .path(.element(_, action: .importOlympiaMnemonic(.delegate(.notPersisted(mnemonicWithPassphrase))))):
			state.mnemonicWithPassphrase = mnemonicWithPassphrase
			guard let selectedAccounts = state.selectedAccounts else {
				assertionFailure("Bad implementation, expected 'state.selectedAccounts' to have been set.")
				return .none
			}
			return validate(mnemonicWithPassphrase, selectedAccounts: selectedAccounts)
		case .path(.element(_, action: .completion(.delegate(.finishedMigration)))):
			return .send(.delegate(.finishedMigration))
		default: return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .validated(accounts, privateHDFactorSource):

			return convertToBabylon(
				olympiaAccounts: accounts,
				factorSource: privateHDFactorSource
			)

		case let .migratedAccounts(migrated):
			let destination = Destinations.State.completion(.init(migratedAccounts: migrated))
			if state.path.last != destination {
				state.path.append(destination)
			}
			return .none
		}
	}
}

extension ImportOlympiaWalletCoordinator {
	private func validate(
		_ mnemonicWithPassphrase: MnemonicWithPassphrase,
		selectedAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
	) -> EffectTask<Action> {
		.run { send in
			try mnemonicWithPassphrase.validatePublicKeysOf(
				selectedAccounts: selectedAccounts
			)

			let privateHDFactorSource = try PrivateHDFactorSource(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				hdOnDeviceFactorSource: FactorSource.olympia(mnemonicWithPassphrase: mnemonicWithPassphrase)
			)
			await send(.internal(.validated(
				olympiaAccounts: selectedAccounts,
				privateHDFactorSource: privateHDFactorSource
			))
			)
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	private func convertToBabylon(
		olympiaAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
		factorSource: PrivateHDFactorSource
	) -> EffectTask<Action> {
		.run { send in
			// Migrates and saved all accounts to Profile
			let migrated = try await accountsClient.migrateOlympiaAccountsToBabylon(
				.init(
					olympiaAccounts: Set(olympiaAccounts.elements),
					olympiaFactorSource: factorSource
				)
			)

			// However, we have not yet saved the factorSource, so lets do that
			let factorSourceToSave = migrated.factorSourceToSave
			guard try factorSourceToSave.id == FactorSource.id(fromPrivateHDFactorSource: factorSource) else {
				throw OlympiaFactorSourceToSaveIDDisrepancy()
			}
			do {
				_ = try await factorSourcesClient.addPrivateHDFactorSource(.init(mnemonicWithPassphrase: factorSource.mnemonicWithPassphrase, hdOnDeviceFactorSource: factorSourceToSave))
			} catch {
				fatalError("todo, handle terrible bad stuff if failed to save factor source (mnemonic) but have already created accounts....")
			}
			await send(.internal(.migratedAccounts(migrated)))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}
}

// MARK: - GotNoAccountsToImport
struct GotNoAccountsToImport: Swift.Error {}

// MARK: - ValidateOlympiaAccountsFailure
enum ValidateOlympiaAccountsFailure: LocalizedError {
	case publicKeyMismatch
}

// MARK: - OlympiaFactorSourceToSaveIDDisrepancy
struct OlympiaFactorSourceToSaveIDDisrepancy: Swift.Error {}

extension MnemonicWithPassphrase {
	func validatePublicKeysOf(
		selectedAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
	) throws {
		let hdRoot = try self.hdRoot()

		for olympiaAccount in selectedAccounts {
			let path = olympiaAccount.path.fullPath
			let derivedPublicKey = try hdRoot.derivePrivateKey(path: path, curve: SECP256K1.self).publicKey
			guard derivedPublicKey == olympiaAccount.publicKey else {
				throw ValidateOlympiaAccountsFailure.publicKeyMismatch
			}
		}
		// PublicKeys matches
	}
}
