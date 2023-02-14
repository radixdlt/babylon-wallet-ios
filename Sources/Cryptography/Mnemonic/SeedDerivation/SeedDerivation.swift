import CommonCrypto
import Prelude

// MARK: - SeedDerivation
public enum SeedDerivation {}

extension SeedDerivation {
	@inlinable
	@inline(__always)
	public static func seedFromMnemonic<M: ContiguousBytes>(
		_ mnemonicData: M,
		passphrase: String
	) throws -> Data {
		let encoding = String.Encoding.utf8
		let keyLength = 64
		let iterations: UInt32 = 2048

		// `... the string "mnemonic" + passphrase (again in UTF-8 NFKD) used as the salt. `
		// https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki#from-mnemonic-to-seed
		let salt = ("mnemonic" + passphrase).decomposedStringWithCompatibilityMapping.data(using: encoding)!

		var seed = Data(repeating: 0, count: keyLength)

		try seed.withUnsafeMutableBytes { seedPointer in
			try mnemonicData.withUnsafeBytes { mnemonicPointer in
				try salt.withUnsafeBytes { saltPointer in
					guard kCCSuccess == CCKeyDerivationPBKDF(
						CCPBKDFAlgorithm(kCCPBKDF2),

						mnemonicPointer.baseAddress?.assumingMemoryBound(to: UInt8.self),
						mnemonicPointer.count,

						saltPointer.baseAddress?.assumingMemoryBound(to: UInt8.self),
						saltPointer.count,

						CCPBKDFAlgorithm(kCCPRFHmacAlgSHA512),
						iterations,

						seedPointer.baseAddress?.assumingMemoryBound(to: UInt8.self),
						seedPointer.count
					) else {
						throw Error.internalError(origin: "PBKDF2")
					}
				}
			}
		}

		// All good
		return seed
	}
}

// MARK: SeedDerivation.Error
extension SeedDerivation {
	public enum Error: Swift.Error, Equatable {
		case internalError(origin: String)
	}
}
