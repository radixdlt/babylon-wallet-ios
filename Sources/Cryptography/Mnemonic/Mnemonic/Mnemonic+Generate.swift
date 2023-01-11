import Foundation

// MARK: Generate
public extension Mnemonic {
	/// Generates a new mnemonic by securely generating random bytes (entropy)
	/// of `wordCount` strength in `language`.
	///
	/// Sugar for `init(wordCount:language)`
	static func generate(
		wordCount: BIP39.WordCount = .default,
		language: BIP39.Language = .default
	) throws -> Self {
		try Self(
			wordCount: wordCount,
			language: language
		)
	}

	/// Generates a new mnemonic by securely generating random bytes (entropy)
	/// of `wordCount` strength in `language`.
	init(
		wordCount: BIP39.WordCount = .default,
		language: BIP39.Language = .default
	) throws {
		let entropy = try BIP39.Entropy(wordCount: wordCount)
		let mnemonicWords = try BIP39.mapEntropyToWords(entropy: entropy, language: language)

		try self.init(words: mnemonicWords, language: language)
	}
}
