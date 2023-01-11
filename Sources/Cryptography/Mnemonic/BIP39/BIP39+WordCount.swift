import Foundation

// MARK: - BIP39.WordCount
public extension BIP39 {
	/// The number of words of a mnemonic, discrete values of BIP39 standard.
	/// A larger word count yields higher entropy and is more secure.
	enum WordCount: Int, CaseIterable, CustomStringConvertible, Sendable, Hashable {
		case twelve = 12
		case fifteen = 15
		case eighteen = 18
		case twentyOne = 21
		case twentyFour = 24
	}
}

public extension BIP39.WordCount {
	static let `default` = Self.twentyFour

	init?(entropyInBits: Int) {
		self.init(rawValue: Self.wordCountFrom(entropyInBits: entropyInBits))
	}

	init?(wordCount: Int) {
		self.init(rawValue: wordCount)
	}

	init?(byteCount: Int) {
		let bitCount = byteCount * bitsPerByte
		self.init(entropyInBits: bitCount)
	}
}

public extension BIP39.WordCount {
	var description: String {
		"\(rawValue) words."
	}
}

public extension BIP39.WordCount {
	/// The number of words of a mnemonic (same as `rawValue`)
	var wordCount: Int {
		rawValue
	}
}

// MARK: - Internal

internal extension BIP39.WordCount {
	static let checksumBitsPerWord = 3

	var byteCount: Int {
		let byteCount = Self.entropyInBitsFrom(wordCount: wordCount) / bitsPerByte
		return byteCount
	}

	static func wordCountFrom(entropyInBits: Int) -> Int {
		Int(ceil(Double(entropyInBits) / Double(BIP39.WordList.sizeLog2)))
	}

	static func entropyInBitsFrom(wordCount: Int) -> Int {
		let ent = wordCount * BIP39.WordList.sizeLog2
		let cs = checksumLengthInBits(wordCount: wordCount)
		let bits = ent - cs
		return bits
	}

	static func checksumLengthInBits(wordCount: Int) -> Int {
		wordCount / BIP39.WordCount.checksumBitsPerWord
	}

	var checksumLengthInBits: Int {
		Self.checksumLengthInBits(wordCount: wordCount)
	}
}
