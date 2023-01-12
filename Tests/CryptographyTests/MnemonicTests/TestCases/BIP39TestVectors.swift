@testable import Cryptography
import Prelude
import TestingPrelude

// MARK: - BIP39Vector
struct BIP39Vector: Equatable {
	let entropy: Data
	let mnemonic: [String]
	let seed: Data
	let key: String
	let passphrase: String

	init(
		entropy: Data,
		mnemonic: [String],
		seed: Data,
		key: String,
		passphrase: String
	) {
		self.entropy = entropy
		self.mnemonic = mnemonic
		self.seed = seed
		self.key = key
		self.passphrase = passphrase
	}

	init(
		entropyHex: String,
		mnemonic: [String],
		seedHex: String,
		key: String,
		passphrase: String
	) throws {
		try self.init(
			entropy: Data(hex: entropyHex),
			mnemonic: mnemonic,
			seed: Data(hex: seedHex),
			key: key,
			passphrase: passphrase
		)
	}
}

// MARK: - EnglishVectors
struct EnglishVectors: Decodable {
	let vectors: [BIP39Vector]

	enum CodingKeys: String, CodingKey {
		case language = "english"
	}

	enum Error: Swift.Error {
		// English format
		case expected4Fields(butGot: Int)
	}

	// English format
	static func toBip39Vector(
		fields: [String]
	) throws -> BIP39Vector {
		guard fields.count == 4 else {
			throw Error.expected4Fields(butGot: fields.count)
		}

		return try BIP39Vector(
			entropyHex: fields[0],
			mnemonic: fields[1].split(separator: " ").map { String($0) },
			seedHex: fields[2],
			key: fields[3],
			passphrase: "TREZOR"
		)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let vectorsRaw = try container.decode([[String]].self, forKey: .language)
		self.vectors = try vectorsRaw.map { try Self.toBip39Vector(fields: $0) }
	}
}

// MARK: - JapaneseVectors
struct JapaneseVectors: Decodable {
	let vectors: [BIP39Vector]

	struct JapaneseVector: Decodable {
		let entropy: String
		let mnemonic: String
		let passphrase: String
		let seed: String
		let bip32_xprv: String

		func toBIP32Vector() throws -> BIP39Vector {
			try .init(
				entropyHex: entropy,
				// The Japanese test vectors separate mnemonic words with "Ideographic Space"
				// https://www.compart.com/en/unicode/U+3000
				// Because why not make life hard? ¯\_(ツ)_/¯
				mnemonic: mnemonic.split(separator: "\u{3000}").map { String($0) },
				seedHex: seed,
				key: bip32_xprv,
				passphrase: passphrase
			)
		}
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let vectorsRaw = try container.decode([JapaneseVector].self)
		self.vectors = try vectorsRaw.map { try $0.toBIP32Vector() }
	}
}

// MARK: - BIP39TestVectors
final class BIP39TestVectors: XCTestCase {
	func testEnglishVectors() throws {
		try orFail {
			try testFixture(
				bundle: .module,
				jsonName: "bip39_english_test_vectors"
			) { (vectors: EnglishVectors) in
				try orFail {
					try doTest(
						vectors: vectors.vectors,
						language: .english
					)
				}
			}
		}
	}

	func testJapanseVectors() throws {
		try orFail {
			try testFixture(
				bundle: .module,
				jsonName: "bip39_japanese_test_vectors"
			) { (vectors: JapaneseVectors) in
				try orFail {
					try doTest(
						vectors: vectors.vectors,
						language: .japanese
					)
				}
			}
		}
	}
}

private extension BIP39TestVectors {
	func doTest(
		vectors: [BIP39Vector],
		language: BIP39.Language,
		file: StaticString = #file, line: UInt = #line
	) throws {
		for vector in vectors {
			try doTest(
				vector: vector,
				language: language,
				file: file, line: line
			)
		}
	}

	func doTest(
		vector: BIP39Vector,
		language: BIP39.Language,
		file: StaticString = #file, line: UInt = #line
	) throws {
		let mnemonic = try Mnemonic(rawEntropy: vector.entropy, language: language)

		XCTAssertEqual(
			mnemonic.words, vector.mnemonic,
			"Mnemonics does not match",
			file: file, line: line
		)

		let seed = try mnemonic.seed(passphrase: vector.passphrase)

		XCTAssertEqual(
			seed, vector.seed,
			"Seed '\(seed.hex())' does not match expected '\(vector.seed.hex())'",
			file: file, line: line
		)

		XCTAssertEqual(
			mnemonic.entropy().data,
			vector.entropy,
			"Entropy mismatch",
			file: file, line: line
		)
	}
}
