import Foundation

public struct AccountsRecoveredFromScanningUsingMnemonic: Sendable, Hashable {
	public let accounts: Profile.Network.Accounts
	public let factorSourceIDOfBDFSAlreadySavedIntoKeychain: FactorSource.ID.FromHash
}
