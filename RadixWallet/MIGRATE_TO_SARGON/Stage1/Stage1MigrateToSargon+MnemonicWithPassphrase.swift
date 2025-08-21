import Foundation
import Sargon

extension MnemonicWithPassphrase {
	func validatePublicKeys(
		of softwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
	) throws {
		guard validate(
			publicKeys: softwareAccounts.map {
				account in
				.init(
					publicKey: account.publicKey.asGeneral,
					derivationPath: account.path.asDerivationPath
				)
			}
		) else {
			throw ValidateMnemonicAgainstEntities.publicKeyMismatch
		}
	}

	func validatePublicKeys(
		of accounts: some Collection<Account>
	) throws {
		guard validate(
			publicKeys: accounts.flatMap { account in
				account.virtualHierarchicalDeterministicFactorInstances.map(\.publicKey)
			}
		) else {
			throw ValidateMnemonicAgainstEntities.publicKeyMismatch
		}
	}
}

// MARK: - ValidateMnemonicAgainstEntities
enum ValidateMnemonicAgainstEntities: LocalizedError {
	case publicKeyMismatch
}
