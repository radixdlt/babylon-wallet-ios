extension UserDefaults.Dependency {
	func addFactorSourceIDOfBackedUpMnemonic(_ factorSourceID: FactorSourceIDFromHash) throws {
		var ids = getFactorSourceIDOfBackedUpMnemonics()
		ids.append(factorSourceID)
		try save(codable: ids, forKey: .mnemonicsUserClaimsToHaveBackedUp)
	}

	func getFactorSourceIDOfBackedUpMnemonics() -> OrderedSet<FactorSourceIDFromHash> {
		(try? loadCodable(key: .mnemonicsUserClaimsToHaveBackedUp)) ?? OrderedSet<FactorSourceIDFromHash>()
	}

	func removeAllFactorSourceIDsOfBackedUpMnemonics() {
		remove(.mnemonicsUserClaimsToHaveBackedUp)
	}

	func factorSourceIDOfBackedUpMnemonics() -> AnyAsyncSequence<OrderedSet<FactorSourceIDFromHash>> {
		codableValues(key: .mnemonicsUserClaimsToHaveBackedUp, codable: OrderedSet<FactorSourceIDFromHash>.self)
			.map { (try? $0.get()) ?? [] }
			.eraseToAnyAsyncSequence()
	}
}
