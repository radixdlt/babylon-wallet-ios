// MARK: - MnemonicClient
struct MnemonicClient: Sendable {
	var generate: Generate
	var `import`: Import
	var lookup: LookupWord
	init(
		generate: @escaping Generate,
		import: @escaping Import,
		lookup: @escaping LookupWord
	) {
		self.generate = generate
		self.import = `import`
		self.lookup = lookup
	}
}

extension MnemonicClient {
	typealias Generate = @Sendable (BIP39WordCount, BIP39Language) -> Mnemonic
	typealias Import = @Sendable (String, BIP39Language?) throws -> Mnemonic
	typealias LookupWord = @Sendable (LookupRequest) -> BIP39LookupResult
}

// MARK: - LookupRequest
struct LookupRequest: Sendable, Hashable {
	let language: BIP39Language
	let input: String
	let minLenghForCandidatesLookup: Int

	init(
		language: BIP39Language,
		input: String,
		minLenghForCandidatesLookup: Int
	) {
		self.language = language
		self.input = input
		self.minLenghForCandidatesLookup = minLenghForCandidatesLookup
	}
}
