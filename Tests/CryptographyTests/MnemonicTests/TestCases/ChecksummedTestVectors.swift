@testable import Cryptography
import TestingPrelude

// MARK: - ChecksummedVector
struct ChecksummedVector: Decodable, Equatable {
	enum CodingKeys: String, CodingKey {
		case mnemonic, seed
	}

	let mnemonic: String
	let seed: Data
	init(mnemonic: String, seed: Data) {
		self.mnemonic = mnemonic
		self.seed = seed
	}

	init(mnemonic: String, seedHex: String) throws {
		try self.init(mnemonic: mnemonic, seed: Data(hex: seedHex))
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let seedHex = try container.decode(String.self, forKey: .seed)
		let mnemonic = try container.decode(String.self, forKey: .mnemonic)
		try self.init(mnemonic: mnemonic, seedHex: seedHex)
	}
}

// MARK: - ChecksummedVectors
struct ChecksummedVectors: Decodable, Equatable {
	let vectors: [ChecksummedVector]
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		self.vectors = try container.decode([ChecksummedVector].self)
	}
}

// MARK: - ChecksummedTestVectors
final class ChecksummedTestVectors: XCTestCase {
	func testChecksummedWithWordCountOf12() throws {
		try orFail {
			try doTestChecksummed(
				jsonName: "bip39_iancoleman_generated_checksummed_wordcount_of_12",
				language: .english
			)
		}
	}

	func testChecksummedWithWordCountOf24() throws {
		try orFail {
			try doTestChecksummed(
				jsonName: "bip39_iancoleman_generated_checksummed_wordcount_of_24",
				language: .english
			)
		}
	}
}

private extension ChecksummedTestVectors {
	func doTestChecksummed(
		jsonName: String,
		language: BIP39.Language,
		file: StaticString = #file, line: UInt = #line
	) throws {
		try orFail {
			try testFixture(
				bundle: .module,
				jsonName: jsonName
			) { (vectors: ChecksummedVectors) in
				try orFail {
					try doTest(
						vectors: vectors.vectors,
						language: language,
						file: file, line: line
					)
				}
			}
		}
	}

	func doTest(
		vectors: [ChecksummedVector],
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
		vector: ChecksummedVector,
		language: BIP39.Language,
		file: StaticString = #file, line: UInt = #line
	) throws {
		let mnemonic = try Mnemonic(phrase: vector.mnemonic, language: language)
		let seed = try mnemonic.seed()
		let wordlist = BIP39.wordList(for: language)

		XCTAssertEqual(
			seed, vector.seed,
			"Seed '\(seed.hex())' does not match expected '\(vector.seed.hex())'",
			file: file, line: line
		)

		let words = mnemonic.words

		guard let firstWordInVocabularyNotPresentInMnemonic = wordlist._list.first(where: { !words.contains($0) }) else {
			return XCTFail(
				"This is not a valid mnemonic, it is 2048 words long!",
				file: file, line: line
			)
		}

		let mnemonicFirstWordReplaced: [String] = {
			var tmp = words
			tmp[0] = firstWordInVocabularyNotPresentInMnemonic
			return tmp

		}()

		XCTAssertThrowsError(
			try Mnemonic(
				words: mnemonicFirstWordReplaced,
				language: language
			),
			"mnemonic with non checksummed words should throw error",
			file: file, line: line
		) { error in
			guard let mnemonicError = error as? BIP39.Error else {
				return XCTFail(
					"wrong error type",
					file: file, line: line
				)
			}

			guard case .validationError(.checksumMismatch) = mnemonicError else {
				return XCTFail(
					"wrong error",
					file: file, line: line
				)
			}
			// ok!
		}
	}
}
