import Foundation

// MARK: From Entropy
public extension Mnemonic {
	/// Attempts to translates `entropy` (checked `Data`) into a BIP39 mnemonic in `language`.
	init(
		entropy: BIP39.Entropy,
		language: BIP39.Language = .default
	) throws {
		let words = try BIP39.mapEntropyToWords(entropy: entropy, language: language)
		try self.init(words: words, language: language)
	}

	/// Attempts to translates `rawEntropy` (`Data`) into a BIP39 mnemonic in `language`.
	init(
		rawEntropy: Data,
		language: BIP39.Language = .default
	) throws {
		let entropy = try BIP39.Entropy(data: rawEntropy)
		try self.init(entropy: entropy, language: language)
	}
}
