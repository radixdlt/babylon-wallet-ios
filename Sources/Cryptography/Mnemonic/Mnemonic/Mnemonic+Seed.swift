import Foundation

// MARK: To Seed
extension Mnemonic {
	/// Derives a binaru seed of this mnemonic using provided `passhrase`
	/// (or empty), as described in [BIP39].
	///
	/// This seed can be later used to generate deterministic wallets using
	/// BIP-0032 or similar methods.
	///
	/// [BIP39]: https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki#From_mnemonic_to_seed
	public func seed(
		passphrase: String = ""
	) throws -> Data {
		let mnemonic = phrase
			.decomposedStringWithCompatibilityMapping
			.data(using: .utf8)!

		let seed = try SeedDerivation.seedFromMnemonic(mnemonic, passphrase: passphrase)

		return seed
	}
}

// MARK: To HDRoot
extension Mnemonic {
	public func hdRoot(passphrase: String = "") throws -> HD.Root {
		try HD.Root(
			seed: seed(passphrase: passphrase)
		)
	}
}
