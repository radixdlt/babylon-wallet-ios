import Prelude

// MARK: - BIP39.WordList
extension BIP39 {
	public struct WordList: Hashable {
		public struct Word: Hashable {
			public typealias Index = UInt11
			public let word: NonEmptyString
			public let index: Index
		}

		public let language: Language
		private let indexToWord: [Word.Index: Word]
		private let wordToIndex: [NonEmptyString: Word.Index]

		// used in tests
		internal let _list: OrderedSet<NonEmptyString>

		enum Error: Swift.Error {
			case invalidWordCount(got: Int, butExpected: Int)
		}

		public init(words wordsArrayMaybeEmpty: [String], language: Language) throws {
			let words = try OrderedSet(validating: wordsArrayMaybeEmpty.compactMap {
				NonEmptyString($0)
			})
			guard words.count == Self.size else {
				throw Error.invalidWordCount(
					got: words.count,
					butExpected: Self.size
				)
			}
			self.language = language

			var indexToWord: [Word.Index: Word] = [:]
			var wordToIndex: [NonEmptyString: Word.Index] = [:]

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
	internal func words(at indices: [Word.Index]) -> OrderedSet<NonEmptyString> {
		OrderedSet(uncheckedUniqueElements: indices.map { index in
			guard let word = self.indexToWord[index] else {
				fatalError("Incorrect implementation, should always be able to located word at index. Index was: \(index), language: \(language)")
			}
			return word.word
		})
	}

	internal func indices(of words: OrderedSet<NonEmptyString>) -> [Word.Index] {
		words.map { wordString in
			guard let index = self.wordToIndex[wordString] else {
				fatalError("Incorrect implementation, should always be able to located index of word. Word was: \(wordString), language: \(language)")
			}
			return index
		}
	}

	internal func missingWord(from words: OrderedSet<NonEmptyString>) -> NonEmptyString? {
		for word in words {
			if self.wordToIndex[word] == nil {
				return word // missing
			}
		}
		return nil // no missing
	}

	public enum LookupResult: Sendable, Hashable {
		case emptyOrTooShort
		case partialAmongstCandidates(OrderedSet<NonEmptyString>)
		case knownFull(NonEmptyString)
		case knownAutocomplete(NonEmptyString)
	}

	public func lookup(
		_ stringMaybeEmpty: String,
		minLengthForPartial: Int = 2,
		ignoreCandidateIfCountExceeds: Int = 5
	) -> LookupResult {
		guard let string = NonEmptyString(rawValue: stringMaybeEmpty) else {
			return .emptyOrTooShort
		}
		if _list.contains(string) {
			return .knownFull(string)
		}

		guard string.count >= minLengthForPartial else {
			return .emptyOrTooShort
		}
		let candidates = _list.filter { $0.starts(with: string) }
		if candidates.count == 1 {
			return .knownAutocomplete(candidates[0])
		}
		guard candidates.count <= ignoreCandidateIfCountExceeds else {
			return .emptyOrTooShort
		}
		return .partialAmongstCandidates(candidates)
	}

	internal func containsAllWords(in words: OrderedSet<NonEmptyString>) -> Bool {
		missingWord(from: words) == nil
	}
}

extension BIP39.WordList {
	internal static let size = 2048

	/// `2^11 => 2048`
	internal static let sizeLog2 = 11
}
