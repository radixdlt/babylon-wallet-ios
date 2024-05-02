import Foundation
import Sargon

public struct AccountsRecoveredFromScanningUsingMnemonic: Sendable, Hashable {
	public let accounts: Accounts
	/// The mnemonic of this BDFS must already have been saved into keychain.
	public let deviceFactorSource: DeviceFactorSource
}
