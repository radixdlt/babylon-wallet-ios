import Foundation

public struct AccountsRecoveredFromScanningUsingMnemonic: Sendable, Hashable {
	public let accounts: Profile.Network.Accounts
	/// The mnemonic of this BDFS must already have been saved into keychain.
	public let deviceFactorSource: DeviceFactorSource
}
