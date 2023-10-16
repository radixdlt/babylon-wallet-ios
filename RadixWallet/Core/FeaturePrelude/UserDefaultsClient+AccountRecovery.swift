
extension UserDefaultsClient {
	public func addAccountsThatNeedRecovery(accounts new: OrderedSet<AccountAddress>) async throws {
		var accounts = getAddressesOfAccountsThatNeedRecovery()
		accounts.append(contentsOf: new)
		try await save(codable: accounts, forKey: .accountsThatNeedRecovery)
	}

	public func removeFromListOfAccountsThatNeedRecovery(accounts toRemove: OrderedSet<AccountAddress>) async throws {
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
		var ids = getFactorSourceIDOfBackedUpMnemonics()
		ids.append(factorSourceID)
		try await save(codable: ids, forKey: .mnemonicsUserClaimsToHaveBackedUp)
	}

	public func getFactorSourceIDOfBackedUpMnemonics() -> OrderedSet<FactorSourceID.FromHash> {
		(try? loadCodable(key: .mnemonicsUserClaimsToHaveBackedUp)) ?? OrderedSet<FactorSourceID.FromHash>()
	}

	public func removeAllFactorSourceIDsOfBackedUpMnemonics() async {
		await setData(nil, .mnemonicsUserClaimsToHaveBackedUp)
	}
}
