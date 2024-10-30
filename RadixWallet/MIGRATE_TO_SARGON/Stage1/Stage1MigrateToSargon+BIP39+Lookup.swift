import Foundation
import Sargon

// MARK: - BIP39LookupResult
enum BIP39LookupResult: Sendable, Hashable {
	case unknown(Unknown)
	case known(Known)

	enum Unknown: Sendable, Hashable {
		/// Text was too short (possible empty)
		case tooShort
		/// Text is known to **not** be in the list
		case notInList(input: NonEmptyString)
	}

	enum Known: Sendable, Hashable {
		enum UnambiguousMatch: Sendable, Hashable {
			/// "zoo" **exactly** and **unambiguously** matches "zoo"
			/// however "cat" exactly, but does **not** unambiguously, match "cat",
			/// because "category" is another candiate.
			case exact

			/// "aban" **unambiguously** matches "abandon", but not **exactly**, it starts with.
			case startsWith
		}

		/// We managed to unambigously identify the word, there are no other candidates which starts with the input
		case unambiguous(BIP39Word, match: UnambiguousMatch, input: NonEmptyString)

		/// We could not unambigously identify the word, but we have some candidates
		case ambigous(candidates: NonEmpty<OrderedSet<BIP39Word>>, input: NonEmptyString)
	}
}

extension [BIP39Word] {
	func lookup(
		language: BIP39Language,
		_ stringMaybeEmpty: String,
		minLengthForCandidatesLookup: Int = 2
	) -> BIP39LookupResult {
		guard
			let string = NonEmptyString(rawValue: stringMaybeEmpty)
		else {
			return .unknown(.tooShort)
		}

		let arrayOfCandidates = self.filter { $0.word.starts(with: string) }
		let setOfCandidates = OrderedSet<BIP39Word>(uncheckedUniqueElements: arrayOfCandidates)

		guard
			let candidates = NonEmpty<OrderedSet<BIP39Word>>(rawValue: setOfCandidates)
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
				match: self.contains(where: { $0.word == string.rawValue }) ? .exact : .startsWith,
				input: string
			)
		)
	}

	func containsAllWords(in words: [NonEmptyString]) -> Bool {
		bip39Words(from: words) != nil
	}

	func bip39Words(from wordStrings: [NonEmptyString]) -> NonEmptyArray<BIP39Word>? {
		guard !wordStrings.isEmpty else { return nil }
		var words: [BIP39Word] = []
		for wordString in wordStrings {
			guard let word = self.first(where: { $0.word == wordString.rawValue }) else {
				return nil
			}
			words.append(word)
		}
		return NonEmpty(rawValue: words)
	}
}

extension BIP39Language {
	/// The number of letters to unambiguously identify the word
	/// https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki#wordlist
	var numberOfCharactersWhichUnambiguouslyIdentifiesWords: Int {
		switch self {
		case .english:
			//  - the wordlist is created in such a way that it's enough to type the first four
			// letters to unambiguously identify the word
			4
		default:
			4 // TODO: verify!
		}
	}
}
