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
	public typealias Generate = @Sendable (BIP39WordCount, BIP39Language) -> Mnemonic
	public typealias Import = @Sendable (String, BIP39Language?) throws -> Mnemonic
	public typealias LookupWord = @Sendable (LookupRequest) -> BIP39LookupResult
}

// MARK: - LookupRequest
public struct LookupRequest: Sendable, Hashable {
	public let language: BIP39Language
	public let input: String
	public let minLenghForCandidatesLookup: Int

	public init(
		language: BIP39Language,
		input: String,
		minLenghForCandidatesLookup: Int
	) {
		self.language = language
		self.input = input
		self.minLenghForCandidatesLookup = minLenghForCandidatesLookup
	}
}
