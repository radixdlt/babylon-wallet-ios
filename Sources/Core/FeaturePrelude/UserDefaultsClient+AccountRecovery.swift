import EngineKit // AccountAddress
import Prelude // UserDefaultsClient

private let accountsThatNeedRecoveryKey = "accountsThatNeedRecoveryKey"
extension UserDefaultsClient {
	public func addAccountsThatNeedRecovery(accounts new: OrderedSet<AccountAddress>) async throws {
		var accounts = getAddressesOfAccountsThatNeedRecovery()
		accounts.append(contentsOf: new)
		try await save(codable: accounts, forKey: accountsThatNeedRecoveryKey)
	}

	public func removeAccountsThatNeedRecoveryIfNeeded(accounts toRemove: OrderedSet<AccountAddress>) async throws {
		var accounts = getAddressesOfAccountsThatNeedRecovery()
		accounts.subtract(toRemove)
		try await save(codable: accounts, forKey: accountsThatNeedRecoveryKey)
	}

	public func getAddressesOfAccountsThatNeedRecovery() -> OrderedSet<AccountAddress> {
		(try? loadCodable(key: accountsThatNeedRecoveryKey)) ?? OrderedSet<AccountAddress>()
	}

	public func removeAccountsThatNeedRecovery() async {
		await setData(nil, accountsThatNeedRecoveryKey)
	}
}

import Profile
private let mnemonicsUserClaimsToHaveBackedUpKey = "mnemonicsUserClaimsToHaveBackedUpKey"
extension UserDefaultsClient {
	public func addFactorSourceIDOfBackedUpMnemonic(_ factorSourceID: FactorSourceID.FromHash) async throws {
		var ids = getFactorSourceIDOfBackedUpMnemonics()
		ids.append(factorSourceID)
		try await save(codable: ids, forKey: mnemonicsUserClaimsToHaveBackedUpKey)
	}

	public func getFactorSourceIDOfBackedUpMnemonics() -> OrderedSet<FactorSourceID.FromHash> {
		(try? loadCodable(key: mnemonicsUserClaimsToHaveBackedUpKey)) ?? OrderedSet<FactorSourceID.FromHash>()
	}

	public func removeAllFactorSourceIDsOfBackedUpMnemonics() async {
		await setData(nil, mnemonicsUserClaimsToHaveBackedUpKey)
	}
}
