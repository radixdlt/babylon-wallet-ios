import CryptoKit
extension BIP39 {
	static func languageFromWords(_ wordsNonChecked: [String]) -> Language? {
		let words = wordsNonChecked.compactMap {
			NonEmptyString(rawValue: $0)
		}
		return BIP39.languageFromWords(words)
	}

	static func languageFromWords(_ words: [NonEmptyString]) -> Language? {
		for langauge in Language.allCases {
			let wordlist = BIP39.wordList(for: langauge)
			if wordlist.containsAllWords(in: words) {
				return langauge
			}
		}

		return nil
	}
}
