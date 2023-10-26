import Foundation
@testable import Radix_Wallet_Dev
import XCTest

final class ImportMnemonicTests: TestCase {
	func test_3_letterword() throws {
		// This is a great mnemonic I've manually crafted (with valid checksum)
		// which contains `add` and `act` being valid words, but with "friends"
		// that are longer, starting with the same letter
		let phrase = "add addict address pen penalty pencil act action actor actress zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo tip"
		let mnemonic = try Mnemonic(phrase: phrase, language: .english)
		let wordsBIP39 = mnemonic.words.rawValue
		let wordStrings = wordsBIP39.map(\.word.rawValue)
		XCTAssertEqual(phrase, wordStrings.joined(separator: " "))

		let store = TestStore(
			initialState: ImportMnemonic.State(
				persistStrategy: nil,
				wordCount: mnemonic.wordCount
			)
		) {
			ImportMnemonic()
		}
		store.exhaustivity = .off
	}
}
