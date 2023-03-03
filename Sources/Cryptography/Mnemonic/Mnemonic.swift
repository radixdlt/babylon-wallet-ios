import Foundation

// MARK: - Mnemonic
public struct Mnemonic: Sendable, Hashable {
	public let words: [String]
	public let wordCount: BIP39.WordCount
	public let language: BIP39.Language

	/// Pass `nil` to `language` if you do not know which language it is, and an attempt to derive
	/// the language based on the words will be made.
	///
	/// Pass `false` to `requireChecksum` if you need to support non-checksummed mnemonics.
	public init(
		words: [String],
		language maybeKnownLanguage: BIP39.Language?,
		requireChecksum: Bool = true
	) throws {
		// Language
		guard
			let language = maybeKnownLanguage ?? BIP39.languageFromWords(words)
		else {
			throw Error.unknownLanguage
		}

		// WordCount
		guard
			let wordCount = BIP39.WordCount(wordCount: words.count)
		else {
			throw Error.invalidWordCount
		}

		// Wordlist
		let wordList = BIP39.wordList(for: language)
		if let missingWord = wordList.missingWord(from: words) {
			throw Error.wordListDoesNotContainWord(missingWord, in: language)
		}

		// Checksum
		if requireChecksum {
			try BIP39.validateChecksumOf(
				mnemonicWords: words,
				language: language
			)
		}

		self.words = words
		self.wordCount = wordCount
		self.language = language
	}
}

extension Mnemonic {
	public var phrase: String { words.joined(separator: String(Self.wordSeparator)) }
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
	public static let testValue: Self = try! Mnemonic(
		phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote",
		language: .english
	)
}
#endif
