import Foundation

public extension Mnemonic {
	static let wordSeparator: Character = " "

	/// Attempts to restores a mnemonic from a bip39 phrase in `language`
	init(
		phrase: String,
		wordSeparator: Character = Self.wordSeparator,
		language maybeKnownLanguage: BIP39.Language?,
		requireChecksum: Bool = true
	) throws {
		let words = phrase.split(separator: wordSeparator).map { String($0) }
		try self.init(
			words: words,
			language: maybeKnownLanguage,
			requireChecksum: requireChecksum
		)
	}
}
