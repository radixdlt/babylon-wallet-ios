import Foundation
import Sargon

struct AccountsRecoveredFromScanningUsingMnemonic: Hashable {
	let accounts: Accounts
	let factorSource: PrivateHierarchicalDeterministicFactorSource
}
