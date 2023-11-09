extension UserDefaults.Dependency {
	public func addFactorSourceIDOfBackedUpMnemonic(_ factorSourceID: FactorSourceID.FromHash) throws {
		var ids = getFactorSourceIDOfBackedUpMnemonics()
		ids.append(factorSourceID)
		try save(codable: ids, forKey: .mnemonicsUserClaimsToHaveBackedUp)
	}

	public func getFactorSourceIDOfBackedUpMnemonics() -> OrderedSet<FactorSourceID.FromHash> {
		(try? loadCodable(key: .mnemonicsUserClaimsToHaveBackedUp)) ?? OrderedSet<FactorSourceID.FromHash>()
	}

	public func removeAllFactorSourceIDsOfBackedUpMnemonics() {
		remove(.mnemonicsUserClaimsToHaveBackedUp)
	}
}
