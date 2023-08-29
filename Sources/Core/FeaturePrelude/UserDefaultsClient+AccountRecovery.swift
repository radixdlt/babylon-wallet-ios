import EngineKit // AccountAddress
import Prelude // UserDefaultsClient
import Profile

extension UserDefaultsClient {
	public func addAccountsThatNeedRecovery(accounts new: OrderedSet<AccountAddress>) async throws {
		var accounts = getAddressesOfAccountsThatNeedRecovery()
		accounts.append(contentsOf: new)
		try await save(codable: accounts, forKey: .accountsThatNeedRecovery)
	}

	public func removeAccountsThatNeedRecoveryIfNeeded(accounts toRemove: OrderedSet<AccountAddress>) async throws {
		var accounts = getAddressesOfAccountsThatNeedRecovery()
		accounts.subtract(toRemove)
		try await save(codable: accounts, forKey: .accountsThatNeedRecovery)
	}

	public func getAddressesOfAccountsThatNeedRecovery() -> OrderedSet<AccountAddress> {
		(try? loadCodable(key: .accountsThatNeedRecovery)) ?? OrderedSet<AccountAddress>()
	}

	public func removeAccountsThatNeedRecovery() async {
		await setData(nil, .accountsThatNeedRecovery)
	}
}

extension UserDefaultsClient {
	public func addFactorSourceIDOfBackedUpMnemonic(_ factorSourceID: FactorSourceID.FromHash) async throws {
		print("adding \(factorSourceID) to mnemonicsUserClaimsToHaveBackedUp")
		var ids = getFactorSourceIDOfBackedUpMnemonics()
		print("READ mnemonicsUserClaimsToHaveBackedUp: \(ids)")
		ids.append(factorSourceID)
		print("UPDATED (not saved) mnemonicsUserClaimsToHaveBackedUp: \(ids)")
		try await save(codable: ids, forKey: .mnemonicsUserClaimsToHaveBackedUp)
		print("after save of mnemonicsUserClaimsToHaveBackedUp: \(getFactorSourceIDOfBackedUpMnemonics())")
	}

	public func getFactorSourceIDOfBackedUpMnemonics() -> OrderedSet<FactorSourceID.FromHash> {
		(try? loadCodable(key: .mnemonicsUserClaimsToHaveBackedUp)) ?? OrderedSet<FactorSourceID.FromHash>()
	}

	public func removeAllFactorSourceIDsOfBackedUpMnemonics() async {
		await setData(nil, .mnemonicsUserClaimsToHaveBackedUp)
	}
}
