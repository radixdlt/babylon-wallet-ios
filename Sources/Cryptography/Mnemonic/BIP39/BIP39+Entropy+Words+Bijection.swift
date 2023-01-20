import Algorithms
import struct CryptoKit.SHA256
import Prelude

internal extension BIP39 {
	static func mapEntropyToWords(
		entropy: Entropy,
		language: Language
	) throws -> [String] {
		let wordlist = BIP39.wordList(for: language)
		let hash = Data(SHA256.hash(data: entropy.data))

		let checkSumBits = BitArray(data: hash).prefix(entropy.wordCount.checksumLengthInBits)

		let bits = BitArray(data: entropy.data) + checkSumBits

		let indices = bits.chunks(ofCount: BIP39.WordList.sizeLog2)
			.map { WordList.Word.Index(bits: $0)! }

		let mnemonicWords = wordlist.words(at: indices)

		return try Self.validateChecksumOf(
			mnemonicWords: mnemonicWords,
			language: language
		)
	}

	/// This is not mapping exactly to the entropy because the mnemonic words contains a checksummed word.
	static func mapWordsToEntropyBitArray(
		words mnemonicWords: [String],
		language: Language
	) throws -> BitArray {
		let wordList = BIP39.wordList(for: language)
		let indices = wordList.indices(of: mnemonicWords)
		return BitArray(indices: indices)
	}
}
