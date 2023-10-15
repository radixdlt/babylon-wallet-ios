import CryptoKit

// MARK: - BIP39.Language
extension BIP39 {
	public enum Language: String, CaseIterable, CustomStringConvertible, Sendable, Hashable {
		case english = "English"
		case japanese = "Japanese"
		case korean = "Korean"
		case spanish = "Spanish"
		case chineseSimplified = "Chinese Simplified"
		case chineseTraditional = "Chinese Traditional"
		case french = "French"
		case italian = "Italian"
	}
}

extension BIP39.Language {
	public static let `default` = Self.english
}

extension BIP39.Language {
	public var description: String {
		rawValue
	}

	/// The number of letters to unambiguously identify the word
	/// https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki#wordlist
	public var numberOfCharactersWhichUnambiguouslyIdentifiesWords: Int {
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
