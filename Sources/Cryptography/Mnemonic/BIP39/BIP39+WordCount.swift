import Prelude

// MARK: - BIP39.WordCount
extension BIP39 {
	/// The number of words of a mnemonic, discrete values of BIP39 standard.
	/// A larger word count yields higher entropy and is more secure.
	public enum WordCount: Int, CaseIterable, CustomStringConvertible, Sendable, Hashable {
		case twelve = 12
		case fifteen = 15
		case eighteen = 18
		case twentyOne = 21
		case twentyFour = 24
	}
}

extension BIP39.WordCount {
	public static let `default` = Self.twentyFour

	public init?(entropyInBits: Int) {
		self.init(rawValue: Self.wordCountFrom(entropyInBits: entropyInBits))
	}

	public init?(wordCount: Int) {
		self.init(rawValue: wordCount)
	}

	public init?(byteCount: Int) {
		let bitCount = byteCount * .bitsPerByte
		self.init(entropyInBits: bitCount)
	}
}

extension BIP39.WordCount {
	public var description: String {
		"\(rawValue) words."
	}
}

extension BIP39.WordCount {
	/// The number of words of a mnemonic (same as `rawValue`)
	public var wordCount: Int {
		rawValue
	}
}

// MARK: - Internal

extension BIP39.WordCount {
	internal static let checksumBitsPerWord = 3

	internal var byteCount: Int {
		let byteCount = Self.entropyInBitsFrom(wordCount: wordCount) / .bitsPerByte
		return byteCount
	}

	internal static func wordCountFrom(entropyInBits: Int) -> Int {
		Int(ceil(Double(entropyInBits) / Double(BIP39.WordList.sizeLog2)))
	}

	internal static func entropyInBitsFrom(wordCount: Int) -> Int {
		let ent = wordCount * BIP39.WordList.sizeLog2
		let cs = checksumLengthInBits(wordCount: wordCount)
		let bits = ent - cs
		return bits
	}

	internal static func checksumLengthInBits(wordCount: Int) -> Int {
		wordCount / BIP39.WordCount.checksumBitsPerWord
	}

	internal var checksumLengthInBits: Int {
		Self.checksumLengthInBits(wordCount: wordCount)
	}
}
