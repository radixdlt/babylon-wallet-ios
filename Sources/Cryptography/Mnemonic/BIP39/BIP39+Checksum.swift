import struct CryptoKit.SHA256
import Prelude

internal extension BIP39 {
	@discardableResult
	static func validateChecksumOf(
		mnemonicWords: [String],
		language: BIP39.Language
	) throws -> [String] {
		let bitArray = try BIP39.mapWordsToEntropyBitArray(words: mnemonicWords, language: language)

		// https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki#generating-the-mnemonic
		// From the table it is not immediately clear, but if you divide `MS` (mnemonicWords.count) by 3
		// you get `CS` (checksumLength).
		let checksumLength = mnemonicWords.count / BIP39.WordCount.checksumBitsPerWord

		let dataBits = BitArray(bitArray.prefix(bitArray.count - checksumLength))
		let checksumBits = BitArray(bitArray.suffix(checksumLength))

		let hash = Data(SHA256.hash(data: dataBits.asData()))

		let hashBits = BitArray(BitArray(data: hash).prefix(checksumLength))

		guard hashBits == checksumBits else {
			throw BIP39.Error.validationError(.checksumMismatch)
		}

		// All is well
		return mnemonicWords
	}
}
