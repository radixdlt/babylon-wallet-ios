
extension MnemonicClient: DependencyKey {
	public typealias Value = MnemonicClient

	public static let liveValue: Self = .init(
		generate: { try Mnemonic(wordCount: $0, language: $1) },
		import: { try Mnemonic(phrase: $0, language: $1) },
		lookup: { request in
			BIP39.wordList(
				for: request.language
			)
			.lookup(
				request.input,
				minLengthForCandidatesLookup: request.minLenghForCandidatesLookup
			)
		}
	)
}
