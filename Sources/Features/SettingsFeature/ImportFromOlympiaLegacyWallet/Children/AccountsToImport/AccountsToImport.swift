import FeaturePrelude
import ImportLegacyWalletClient

// MARK: - AccountsToImport
public struct AccountsToImport: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let scannedAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>

		public init(
			scannedAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
		) {
			self.scannedAccounts = scannedAccounts
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case continueButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case continueImport
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .continueButtonTapped:
			return .send(.delegate(.continueImport))
		}
	}
}

/*
 - scanQR
 case let .scanQR(.delegate(.finishedScanning(olympiaWallet))):
 state.expectedMnemonicWordCount = olympiaWallet.mnemonicWordCount
 let scanned = olympiaWallet.accounts
 case let .foundAlreadyImportedOlympiaSoftwareAccounts(scanned, alreadyImported):
 state.accountsToImport = accountsToImport
 - accountsToImport
 case .accountsToImport(.delegate(.continueImport)):

 if let softwareAccounts = state.softwareAccountsToMigrate {
    return migrateSoftwareAccounts(softwareAccounts):
 return .internal(.checkedIfOlympiaFactorSourceAlreadyExists(idOfExistingFactorSource))
 if let idOfExistingFactorSource {
 convertSoftwareAccountsToBabylon

 case let .migratedOlympiaSoftwareAccounts(migratedSoftwareAccounts):
 state.migratedAccounts.append(contentsOf: migratedSoftwareAccounts.babylonAccounts.rawValue)
 return migrateHardwareAccounts(hardwareAccounts)

 } else {
 - .importMnemonic(.init(persistAsMnemonicKind: nil, wordCount: expectedWordCount))
 case let .importMnemonic(.delegate(.notSavedInProfile(mnemonicWithPassphrase))):
 state.mnemonicWithPassphrase = mnemonicWithPassphrase
 return validateSoftwareAccounts(mnemonicWithPassphrase, softwareAccounts: softwareAccounts)
 convertSoftwareAccountsToBabylon
 }

 - importMnemonic

 } else if let hardwareAccounts = state.hardwareAccountsToMigrate {
 return migrateHardwareAccounts(hardwareAccounts)
 - .importOlympiaLedgerAccountsAndFactorSources
 case let .importOlympiaLedgerAccountsAndFactorSources(.delegate(.completed(ledgersWithAccounts, unvalidatedOlympiaAccounts))):
 append migratedAccounts.append
 - .completion
 }
 */
