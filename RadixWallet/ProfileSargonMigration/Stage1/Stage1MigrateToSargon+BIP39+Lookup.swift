import Foundation
import Sargon

public enum BIP39LookupResult: Sendable, Hashable {
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
		case unambiguous(BIP39Word, match: UnambiguousMatch, input: NonEmptyString)

		/// We could not unambigously identify the word, but we have some candidates
		case ambigous(candidates: NonEmpty<OrderedSet<BIP39Word>>, input: NonEmptyString)
	}
}
