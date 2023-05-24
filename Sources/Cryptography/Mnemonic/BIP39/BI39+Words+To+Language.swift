import Prelude

extension BIP39 {
	internal static func languageFromWords(_ wordsNonChecked: [String]) -> Language? {
		guard let words = try? OrderedSet<NonEmptyString>(validating: wordsNonChecked.compactMap {
			NonEmptyString(rawValue: $0)
		}) else {
			return nil
		}
		return BIP39.languageFromWords(words)
	}

	internal static func languageFromWords(_ words: OrderedSet<NonEmptyString>) -> Language? {
		for langauge in Language.allCases {
			let wordlist = BIP39.wordList(for: langauge)
			if wordlist.containsAllWords(in: words) {
				return langauge
			}
		}

		return nil
	}
}
