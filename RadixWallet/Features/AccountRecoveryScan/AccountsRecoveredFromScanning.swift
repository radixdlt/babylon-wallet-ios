import Foundation
import Sargon

struct AccountsRecoveredFromScanningUsingMnemonic: Sendable, Hashable {
	let accounts: Accounts
	/// The mnemonic of this BDFS must already have been saved into keychain.
	let deviceFactorSource: DeviceFactorSource
}
