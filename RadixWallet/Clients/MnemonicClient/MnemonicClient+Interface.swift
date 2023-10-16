// MARK: - MnemonicClient
public struct MnemonicClient: Sendable {
	public var generate: Generate
	public var `import`: Import
	public var lookup: LookupWord
	public init(
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
	public typealias Generate = @Sendable (BIP39.WordCount, BIP39.Language) throws -> Mnemonic
	public typealias Import = @Sendable (String, BIP39.Language?) throws -> Mnemonic
	public typealias LookupWord = @Sendable (LookupRequest) -> BIP39.WordList.LookupResult
}

// MARK: - LookupRequest
public struct LookupRequest: Sendable, Hashable {
	public let language: BIP39.Language
	public let input: String
	public let minLenghForCandidatesLookup: Int

	public init(
		language: BIP39.Language,
		input: String,
		minLenghForCandidatesLookup: Int
	) {
		self.language = language
		self.input = input
		self.minLenghForCandidatesLookup = minLenghForCandidatesLookup
	}
}
