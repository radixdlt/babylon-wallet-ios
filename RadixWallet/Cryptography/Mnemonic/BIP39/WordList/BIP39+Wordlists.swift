import CryptoKit
extension BIP39 {
	fileprivate static var cachedWordLists: [Language: WordList] = [:]

	fileprivate static func words(for language: Language) -> [String] {
		switch language {
		case .english:
			WordList.english
		case .japanese:
			WordList.japanese
		case .korean:
			WordList.korean
		case .spanish:
			WordList.spanish
		case .chineseSimplified:
			WordList.chineseSimplified
		case .chineseTraditional:
			WordList.chineseTraditional
		case .french:
			WordList.french
		case .italian:
			WordList.italian
		}
	}

	fileprivate static func makeWordList(for language: Language) -> WordList {
		let words = words(for: language)
		return try! WordList(words: words, language: language)
	}
}

extension BIP39 {
	public static func wordList(for language: Language) -> WordList {
		if let list = cachedWordLists[language] {
			return list
		}
		let newList = makeWordList(for: language)
		cachedWordLists[language] = newList
		return newList
	}
}
