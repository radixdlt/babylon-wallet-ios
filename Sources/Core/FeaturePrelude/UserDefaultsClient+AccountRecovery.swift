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
