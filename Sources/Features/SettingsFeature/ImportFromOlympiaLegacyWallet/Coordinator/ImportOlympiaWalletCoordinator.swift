import Cryptography
import FeaturePrelude

// MARK: - ImportOlympiaWalletCoordinator
public struct ImportOlympiaWalletCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Step: Sendable, Hashable {
			case scanMultipleOlympiaQRCodes(ScanMultipleOlympiaQRCodes.State)
			case selectAccountsToImport(SelectAccountsToImport.State)
			case importOlympiaMnemonic(ImportOlympiaFactorSource.State)
		}

		public var expectedMnemonicWordCount: BIP39.WordCount?
		public var selectedAccounts: NonEmpty<OrderedSet<ImportedOlympiaWallet.Account>>?
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
		case createdUnsavedOlympiaAccounts(Profile.Network.Accounts)
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.errorQueue) var errorQueue
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.step, action: /Action.self) {
			EmptyReducer()
				.ifCaseLet(/State.Step.scanMultipleOlympiaQRCodes, action: /Action.child .. ChildAction.scanMultipleOlympiaQRCodes) {
					ScanMultipleOlympiaQRCodes()
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
		case let .createdUnsavedOlympiaAccounts(accounts):
			fatalError()
		}
	}
}

extension ImportOlympiaWalletCoordinator {
	private func validate(
		_ mnemonicWithPassphrase: MnemonicWithPassphrase,
		selectedAccounts: NonEmpty<OrderedSet<ImportedOlympiaWallet.Account>>
	) -> EffectTask<Action> {
		.run { send in
			let olympiaAccounts = try mnemonicWithPassphrase.createUnsavedAccountsFrom(selectedAccounts: selectedAccounts)
			await send(.internal(.createdUnsavedOlympiaAccounts(olympiaAccounts)))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}
}

// MARK: - GotNoAccountsToImport
struct GotNoAccountsToImport: Swift.Error {}

// MARK: - ValidateOlympiaAccountsFailure
enum ValidateOlympiaAccountsFailure: LocalizedError {
	case foobar
}

extension MnemonicWithPassphrase {
	func createUnsavedAccountsFrom(
		selectedAccounts: NonEmpty<OrderedSet<ImportedOlympiaWallet.Account>>
	) throws -> Profile.Network.Accounts {
		fatalError()
	}
}
