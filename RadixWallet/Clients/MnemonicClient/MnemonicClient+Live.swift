
extension MnemonicClient: DependencyKey {
	public typealias Value = MnemonicClient

	public static let liveValue: Self = .init(
		generate: {
//			try Mnemonic(wordCount: $0, language: $1)
			Mnemonic.init
			sargonProfileFinishMigrateAtEndOfStage1()
		},
		import: { _, _ in
//			try Mnemonic(phrase: $0, language: $1)
			sargonProfileFinishMigrateAtEndOfStage1()
		},
		lookup: { _ in
//			BIP39.wordList(
//				for: request.language
//			)
//			.lookup(
//				request.input,
//				minLengthForCandidatesLookup: request.minLenghForCandidatesLookup
//			)
			sargonProfileFinishMigrateAtEndOfStage1()
		}
	)
}
