import CryptoKit

// MARK: - Mnemonic
public struct Mnemonic: Sendable, Hashable, CustomDebugStringConvertible {
	public let words: NonEmptyArray<BIP39.Word>
	public let wordCount: BIP39.WordCount
	public let language: BIP39.Language

	/// Pass `nil` to `language` if you do not know which language it is, and an attempt to derive
	/// the language based on the words will be made.
	///
	/// Pass `false` to `requireChecksum` if you need to support non-checksummed mnemonics.
	public init(
		words wordsNonChecked: [String],
		language maybeKnownLanguage: BIP39.Language?,
		requireChecksum: Bool = true
	) throws {
		let words: [NonEmptyString] = wordsNonChecked.compactMap {
			NonEmptyString(rawValue: $0)
		}
		try self.init(words: words, language: maybeKnownLanguage, requireChecksum: requireChecksum)
	}
}

extension Mnemonic {
	public init(
		words wordStrings: [NonEmptyString],
		language maybeKnownLanguage: BIP39.Language?,
		requireChecksum: Bool = true
	) throws {
		// Language
		guard
			let language = maybeKnownLanguage ?? BIP39.languageFromWords(wordStrings)
		else {
			throw Error.unknownLanguage
		}

		// Wordlist
		let wordList = BIP39.wordList(for: language)
		guard let words = wordList.bip39Words(from: wordStrings) else {
			throw Error.wordListDoesNotContainWord(language)
		}

		try self.init(words: words, requireChecksum: requireChecksum)
	}

	public init(
		words wordsMaybeEmpty: [BIP39.Word],
		requireChecksum: Bool = true
	) throws {
		guard let words = NonEmptyArray(rawValue: wordsMaybeEmpty) else {
			throw Error.invalidWordCount
		}
		try self.init(words: words, requireChecksum: requireChecksum)
	}

	public init(
		words: NonEmptyArray<BIP39.Word>,
		requireChecksum: Bool = true
	) throws {
		// WordCount
		guard
			let wordCount = BIP39.WordCount(wordCount: words.count)
		else {
			throw Error.invalidWordCount
		}

		let language = words[0].language
		guard words.allSatisfy({ $0.language == language }) else {
			throw Error.mixedLanguage
		}

		// Checksum
		if requireChecksum {
			try BIP39.validateChecksumOf(
				mnemonicWords: words.rawValue,
				language: language
			)
		}

		self.words = words
		self.wordCount = wordCount
		self.language = language
	}
}

extension Mnemonic {
	public var phrase: NonEmptyString {
		precondition(!words.isEmpty)
		guard let phrase = NonEmptyString(
			rawValue: words.map(\.word.rawValue).joined(separator: String(Self.wordSeparator))
		) else {
			fatalError("Expected phrase to never be empty, was `words` empty?")
		}
		return phrase
	}

	public var debugDescription: String {
		phrase.rawValue
	}
}

// MARK: Codable
extension Mnemonic: Codable {
	public init(from decoder: Decoder) throws {
		let singleValueContainer = try decoder.singleValueContainer()
		let phrase = try singleValueContainer.decode(String.self)
		try self.init(phrase: phrase, language: nil)
	}

	public func encode(to encoder: Encoder) throws {
		var singleValueContainer = encoder.singleValueContainer()
		try singleValueContainer.encode(phrase)
	}
}

#if DEBUG
extension Mnemonic {
	public static let testValue = Self.testValueZooVote

	/// 24 word
	public static let testValueZooVote: Self = try! Mnemonic(
		phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote",
		language: .english
	)

	/// 24 word
	public static let testValueAbandonArt: Self = try! Mnemonic(
		phrase: "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art",
		language: .english
	)
}
#endif
