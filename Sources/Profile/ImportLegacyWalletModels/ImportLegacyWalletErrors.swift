import Foundation

// MARK: - ImportedOlympiaWalletFailPayloadsEmpty
struct ImportedOlympiaWalletFailPayloadsEmpty: Swift.Error {}

// MARK: - ImportedOlympiaWalletFailInvalidWordCount
struct ImportedOlympiaWalletFailInvalidWordCount: Swift.Error {}

// MARK: - ExpectedSoftwareAccount
struct ExpectedSoftwareAccount: Error {}

// MARK: - ExpectedHardwareAccount
struct ExpectedHardwareAccount: Error {}

// MARK: - NetworkIDDisrepancy
struct NetworkIDDisrepancy: Swift.Error {}

// MARK: - ExpectedBIP44LikeDerivationPathToAlwaysContainAddressIndex
struct ExpectedBIP44LikeDerivationPathToAlwaysContainAddressIndex: Swift.Error {}
