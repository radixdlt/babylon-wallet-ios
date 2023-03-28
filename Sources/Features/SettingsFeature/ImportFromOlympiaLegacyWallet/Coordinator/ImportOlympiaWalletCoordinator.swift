import AccountsClient
import Cryptography
import FeaturePrelude
import Profile

// MARK: - ImportOlympiaWalletCoordinator
public struct ImportOlympiaWalletCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Step: Sendable, Hashable {
			case scanMultipleOlympiaQRCodes(ScanMultipleOlympiaQRCodes.State)
			case selectAccountsToImport(SelectAccountsToImport.State)
			case importOlympiaMnemonic(ImportOlympiaFactorSource.State)
		}

		public var expectedMnemonicWordCount: BIP39.WordCount?
		public var selectedAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>?
		public var mnemonicWithPassphrase: MnemonicWithPassphrase?
		public var step: Step
		public init() {
			step = .scanMultipleOlympiaQRCodes(.init())
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum ChildAction: Sendable, Equatable {
		case scanMultipleOlympiaQRCodes(ScanMultipleOlympiaQRCodes.Action)
		case selectAccountsToImport(SelectAccountsToImport.Action)
		case importOlympiaMnemonic(ImportOlympiaFactorSource.Action)
	}

	public enum InternalAction: Sendable, Equatable {
		case validated(
			olympiaAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
			privateHDFactorSource: PrivateHDFactorSource
		)
		case migratedAccounts(MigratedAccounts)
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.step, action: /Action.self) {
			EmptyReducer()
				.ifCaseLet(/State.Step.scanMultipleOlympiaQRCodes, action: /Action.child .. ChildAction.scanMultipleOlympiaQRCodes) {
					ScanMultipleOlympiaQRCodes()
				}
				.ifCaseLet(/State.Step.selectAccountsToImport, action: /Action.child .. ChildAction.selectAccountsToImport) {
					SelectAccountsToImport()
				}
				.ifCaseLet(/State.Step.importOlympiaMnemonic, action: /Action.child .. ChildAction.importOlympiaMnemonic) {
					ImportOlympiaFactorSource()
				}
		}

		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .scanMultipleOlympiaQRCodes(.delegate(.finishedScanning(olympiaWallet))):
			state.expectedMnemonicWordCount = olympiaWallet.mnemonicWordCount
			state.step = .selectAccountsToImport(.init(scannedAccounts: olympiaWallet.accounts))
			return .none

		case let .selectAccountsToImport(.delegate(.selectedAccounts(accounts))):
			state.selectedAccounts = accounts
			state.step = .importOlympiaMnemonic(.init(shouldPersist: false))
			return .none

		case let .importOlympiaMnemonic(.delegate(.notPersisted(mnemonicWithPassphrase))):
			state.mnemonicWithPassphrase = mnemonicWithPassphrase
			guard let selectedAccounts = state.selectedAccounts else {
				fatalError()
			}
			return validate(mnemonicWithPassphrase, selectedAccounts: selectedAccounts)

		default: return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .validated(accounts, privateHDFactorSource):
			return convertToBabylon(olympiaAccounts: accounts, factorSource: privateHDFactorSource)
		case let .migratedAccounts(migrated):
			fatalError()
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
			// Factor source is not yet saved to profile
			let unsavedMigratedAccounts = try await accountsClient.migrateOlympiaAccountsToBabylon(
				Set(olympiaAccounts.elements)
			)
			await send(.internal(.migratedAccounts(unsavedMigratedAccounts)))
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
