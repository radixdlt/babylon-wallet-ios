import CryptoKit
extension Mnemonic {
	public enum Error: Swift.Error {
		/// Might occur when trying to create a mnemonic from a list of words
		/// when the language is not known.
		case unknownLanguage

		/// BIP39.Words of different languages found in list
		case mixedLanguage

		/// Might occur when initializing a mnemonic from a list of words, of
		/// incorrect length.
		case invalidWordCount

		/// Might occur when initializing a mnemonic from a list of words, where
		/// one **or more** words where not found in the word list of the
		/// language.
		case wordListDoesNotContainWord(BIP39.Language)
	}
}
