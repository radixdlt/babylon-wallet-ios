import Sargon

// MARK: - MnemonicClient + DependencyKey
extension MnemonicClient: DependencyKey {
	public typealias Value = MnemonicClient

	public static let liveValue: Self = .init(
		generate: {
			Mnemonic(wordCount: $0, language: $1)
		},
		import: {
			try Mnemonic(phrase: $0, language: $1)
		},
		lookup: { request in
			request.language.wordlist()
				.lookup(
					language: request.language,
					request.input,
					minLengthForCandidatesLookup: request.minLenghForCandidatesLookup
				)
		}
	)
}
