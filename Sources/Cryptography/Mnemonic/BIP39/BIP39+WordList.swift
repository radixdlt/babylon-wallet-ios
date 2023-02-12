import Prelude

// MARK: - BIP39.WordList
extension BIP39 {
	public struct WordList: Hashable {
		public struct Word: Hashable {
			public typealias Index = UInt11
			public let word: String
			public let index: Index
		}

		public let language: Language
		private let indexToWord: [Word.Index: Word]
		private let wordToIndex: [String: Word.Index]

		// used in tests
		internal let _list: [String]

		enum Error: Swift.Error {
			case invalidWordCount(got: Int, butExpected: Int)
		}

		public init(words: [String], language: Language) throws {
			guard words.count == Self.size else {
				throw Error.invalidWordCount(got: words.count, butExpected: Self.size)
			}
			self.language = language

			var indexToWord: [Word.Index: Word] = [:]
			var wordToIndex: [String: Word.Index] = [:]

			for (indexInt, wordString) in words.enumerated() {
				let index = Word.Index(exactly: indexInt)!
				let word = Word(word: wordString, index: index)
				wordToIndex[wordString] = index
				indexToWord[index] = word
			}

			self.indexToWord = indexToWord
			self.wordToIndex = wordToIndex
			self._list = words
		}
	}
}

extension BIP39.WordList {
	internal func words(at indices: [Word.Index]) -> [String] {
		indices.map { index in
			guard let word = self.indexToWord[index] else {
				fatalError("Incorrect implementation, should always be able to located word at index. Index was: \(index), language: \(language)")
			}
			return word.word
		}
	}

	internal func indices(of words: [String]) -> [Word.Index] {
		words.map { wordString in
			guard let index = self.wordToIndex[wordString] else {
				fatalError("Incorrect implementation, should always be able to located index of word. Word was: \(wordString), language: \(language)")
			}
			return index
		}
	}

	internal func missingWord(from words: [String]) -> String? {
		for word in words {
			if self.wordToIndex[word] == nil {
				return word // missing
			}
		}
		return nil // no missing
	}

	internal func containsAllWords(in words: [String]) -> Bool {
		missingWord(from: words) == nil
	}
}

extension BIP39.WordList {
	internal static let size = 2048

	/// `2^11 => 2048`
	internal static let sizeLog2 = 11
}
