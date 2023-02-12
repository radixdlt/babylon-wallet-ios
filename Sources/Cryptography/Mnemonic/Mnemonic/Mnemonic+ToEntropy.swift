import Prelude

extension Mnemonic {
	/// Translates this mnemonic into the original entropy that was used to
	/// create this mnemonic.
	public func entropy() -> BIP39.Entropy {
		do {
			return try mapToEntropy()
		} catch {
			fatalError("Incorrect implementation, should always be able to map mnemonic to entropy but got error: \(error)")
		}
	}
}

extension Mnemonic {
	private func mapToEntropy() throws -> BIP39.Entropy {
		let entropyIncludingChecksum = try BIP39.mapWordsToEntropyBitArray(words: self.words, language: self.language)
		let entropyExcludingChecksum = BitArray(entropyIncludingChecksum.dropLast(self.wordCount.checksumLengthInBits))
		return try BIP39.Entropy(data: entropyExcludingChecksum.asData())
	}
}
