@testable import Cryptography
import TestingPrelude

public final class MnemonicTests: XCTestCase {
	func testGenerateManyAndVerifyChecksummed() {
		for wordCount in BIP39.WordCount.allCases {
			for language in BIP39.Language.allCases {
				for _ in 0 ..< 10 {
					XCTAssertNoThrow(
						try Mnemonic.generate(wordCount: wordCount, language: language)
					)
				}
			}
		}
	}

	func testChecksumValidation() throws {
		let phrase = "gown pulp squeeze squeeze chuckle glance skill glare force dog absurd tennis"
		XCTAssertNoThrow(try Mnemonic(phrase: phrase, language: .english))
		let lastWordReplaced = phrase.replacingOccurrences(of: "absurd tennis", with: "absurd cat")
		XCTAssertThrowsError(try Mnemonic(phrase: lastWordReplaced, language: .english))
		XCTAssertNoThrow(try Mnemonic(phrase: lastWordReplaced, language: .english, requireChecksum: false))
	}
}
