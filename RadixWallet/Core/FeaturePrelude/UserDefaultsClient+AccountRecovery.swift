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
