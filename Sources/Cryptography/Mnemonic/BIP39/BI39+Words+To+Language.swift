import Foundation

internal extension BIP39 {
	static func languageFromWords(_ words: [String]) -> Language? {
		for langauge in Language.allCases {
			let wordlist = BIP39.wordList(for: langauge)
			if wordlist.containsAllWords(in: words) {
				return langauge
			}
		}

		return nil
	}
}
