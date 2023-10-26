import Foundation
@testable import Radix_Wallet_Dev
import XCTest

// MARK: - ImportMnemonicTests
// These a great mnemonics I've manually crafted (with valid checksum)
// which contains `add` and `act` being valid words, but with "friends"
// that are longer, starting with the same letter.
@MainActor
final class ImportMnemonicTests: TestCase {
	func test_3_letterword_12_words() async throws {
		try await doTest(
			mnemonic: "add addict address pen penalty pencil act action actor actress zoo wreck"
		)
	}

	func test_3_letterword_24_words() async throws {
		try await doTest(
			mnemonic: "add addict address pen penalty pencil act action actor actress zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo tip"
		)
	}
}

extension ImportMnemonicTests {
	private func doTest(mnemonic phrase: String) async throws {
		let mnemonic = try Mnemonic(phrase: phrase, language: .english)
		let wordsBIP39 = mnemonic.words.rawValue
		let wordStrings = wordsBIP39.map(\.word.rawValue)
		XCTAssertEqual(phrase, wordStrings.joined(separator: " "))
		let testClock = TestClock()
		let store = TestStore(
			initialState: ImportMnemonic.State(
				persistStrategy: nil,
				wordCount: mnemonic.wordCount
			)
		) {
			ImportMnemonic()
		} withDependencies: {
			$0.continuousClock = testClock
			$0.mnemonicClient = .liveValue
		}

		store.exhaustivity = .off

		for (index, wordBIP39) in wordsBIP39.enumerated() {
			let word4Letters = String(wordBIP39.word.rawValue.prefix(4))
			await store.send(
				.child(
					.word(
						id: index,
						child: .view(.wordChanged(input: word4Letters))
					)
				)
			)
			await store.send(
				.child(
					.word(
						id: index,
						child: .delegate(.lostFocus(displayText: word4Letters))
					)
				)
			)
		}
		XCTAssertEqual(store.state.mnemonic, mnemonic)
	}
}
