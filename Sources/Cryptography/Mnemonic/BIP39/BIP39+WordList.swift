import Prelude

// MARK: - BIP39.WordList
extension BIP39 {
	public struct Word: Sendable, Hashable, Comparable {
		public typealias Index = UInt11
		public let word: NonEmptyString
		public let index: Index
		public let language: Language
		public static func < (lhs: Self, rhs: Self) -> Bool {
			lhs.index < rhs.index
		}
	}

	public struct WordList: Sendable, Hashable {
		public typealias Word = BIP39.Word
		public let language: Language
		public let indexToWord: [Word.Index: Word]
		public let wordToIndex: [NonEmptyString: Word.Index]

		public let words: NonEmpty<OrderedSet<Word>>

		enum Error: Swift.Error {
			case invalidWordCount(got: Int, butExpected: Int)
		}

		public init(words wordsArrayMaybeEmpty: [String], language: Language) throws {
			let wordsStrings = try OrderedSet(validating: wordsArrayMaybeEmpty.compactMap {
				NonEmptyString($0)
			})
			assert(wordsStrings.count == wordsArrayMaybeEmpty.count)
			guard wordsStrings.count == Self.size else {
				throw Error.invalidWordCount(
					got: wordsStrings.count,
					butExpected: Self.size
				)
			}
			self.language = language

			var indexToWord: [Word.Index: Word] = [:]
			var wordToIndex: [NonEmptyString: Word.Index] = [:]

			var words: OrderedSet<Word> = []
			for (indexInt, wordString) in wordsStrings.enumerated() {
				let index = Word.Index(exactly: indexInt)!
				let word = Word(word: wordString, index: index, language: language)
				wordToIndex[wordString] = index
				indexToWord[index] = word
				words.append(word)
			}

			self.indexToWord = indexToWord
			self.wordToIndex = wordToIndex
			self.words = .init(rawValue: words)!
			assert(words.count == wordsStrings.count)
		}
	}
}

extension BIP39.WordList {
	internal func words(at indices: [Word.Index]) -> [Word] {
		indices.map { index in
			guard let word = self.indexToWord[index] else {
				fatalError("Incorrect implementation, should always be able to located word at index. Index was: \(index), language: \(language)")
			}
			return word
		}
	}

	internal func indices(of words: [NonEmptyString]) -> [Word.Index] {
		words.map { wordString in
			guard let index = self.wordToIndex[wordString] else {
				fatalError("Incorrect implementation, should always be able to located index of word. Word was: \(wordString), language: \(language)")
			}
			return index
		}
	}

	internal func bip39Words(from wordStrings: [NonEmptyString]) -> NonEmptyArray<Word>? {
		guard !wordStrings.isEmpty else { return nil }
		var words: [Word] = []
		for wordString in wordStrings {
			guard let word = self.words.first(where: { $0.word == wordString }) else {
				return nil
			}
			words.append(word)
		}
		return NonEmpty(rawValue: words)
	}

	public enum LookupResult: Sendable, Hashable {
		case unknown(Unknown)
		case known(Known)

		public enum Unknown: Sendable, Hashable {
			/// Text was too short (possible empty)
			case tooShort
			/// Text is known to **not** be in the list
			case notInList(input: NonEmptyString)
		}

		public enum Known: Sendable, Hashable {
			public enum UnambiguousMatch: Sendable, Hashable {
				/// "zoo" **exactly** and **unambiguously** matches "zoo"
				/// however "cat" exactly, but does **not** unambiguously, match "cat",
				/// because "category" is another candiate.
				case exact

				/// "aban" **unambiguously** matches "abandon", but not **exactly**, it starts with.
				case startsWith
			}

			/// We managed to unambigously identify the word, there are no other candidates which starts with the input
			case unambiguous(BIP39.Word, match: UnambiguousMatch, input: NonEmptyString)

			/// We could not unambigously identify the word, but we have some candidates
			case ambigous(candidates: NonEmpty<OrderedSet<BIP39.Word>>, input: NonEmptyString)
		}
	}

	public func lookup(
		_ stringMaybeEmpty: String,
		minLengthForCandidatesLookup: Int = 2
	) -> LookupResult {
		guard
			let string = NonEmptyString(rawValue: stringMaybeEmpty)
		else {
			return .unknown(.tooShort)
		}

		let arrayOfCandidates = words.filter { $0.word.starts(with: string) }
		let setOfCandidates = OrderedSet<BIP39.Word>.init(uncheckedUniqueElements: arrayOfCandidates)

		guard
			let candidates = NonEmpty<OrderedSet<BIP39.Word>>(rawValue: setOfCandidates)
		else {
			if string.count >= language.numberOfCharactersWhichUnambiguouslyIdentifiesWords {
				return .unknown(.notInList(input: string))
			} else if string.count >= minLengthForCandidatesLookup {
				return .unknown(.tooShort)
			} else {
				// e.g. "x" which no word starts with in English, yielding no candidates.
				return .unknown(.notInList(input: string))
			}
		}

		guard candidates.count == 1 else {
			return .known(.ambigous(candidates: candidates, input: string))
		}

		return .known(
			.unambiguous(
				candidates.first,
				match: words.contains(string) ? .exact : .startsWith,
				input: string
			)
		)
	}

	internal func containsAllWords(in words: [NonEmptyString]) -> Bool {
		bip39Words(from: words) != nil
	}
}

extension NonEmpty<OrderedSet<BIP39.Word>> {
	func contains(_ string: NonEmptyString) -> Bool {
		contains(where: { $0.word == string })
	}
}

extension BIP39.WordList {
	internal static let size = 2048

	/// `2^11 => 2048`
	internal static let sizeLog2 = 11
}
