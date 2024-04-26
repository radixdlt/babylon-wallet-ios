import Foundation
import Sargon

extension MnemonicWithPassphrase {
	@discardableResult
	public func validatePublicKeys(
		of softwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
	) throws -> Bool {
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
		return true
	}

	public func validatePublicKeys(
		of accounts: some Collection<Account>
	) throws -> Bool {
		guard validate(
			publicKeys: accounts.flatMap { account in
				account.virtualHierarchicalDeterministicFactorInstances.map(\.publicKey)
			}
		) else {
			throw ValidateMnemonicAgainstEntities.publicKeyMismatch
		}
		return true
	}
}

// MARK: - ValidateMnemonicAgainstEntities
enum ValidateMnemonicAgainstEntities: LocalizedError {
	case publicKeyMismatch
}
