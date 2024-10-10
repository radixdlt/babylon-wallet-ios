import Foundation
import Sargon

public struct AccountsRecoveredFromScanningUsingMnemonic: Sendable, Hashable {
	public let accounts: Accounts
	public let factorSource: PrivateHierarchicalDeterministicFactorSource
}
