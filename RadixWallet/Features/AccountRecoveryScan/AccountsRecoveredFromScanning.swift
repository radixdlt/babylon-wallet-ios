import Foundation
import Sargon

struct AccountsRecoveredFromScanningUsingMnemonic: Sendable, Hashable {
	let accounts: Accounts
	let factorSource: PrivateHierarchicalDeterministicFactorSource
}
