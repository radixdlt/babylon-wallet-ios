import Foundation
@testable import Radix_Wallet_Dev
import Sargon
import XCTest

// MARK: - ImportMnemonicGridTests
// These a great mnemonics I've manually crafted (with valid checksum)
// which contains `add` and `act` being valid words, but with "friends"
// that are longer, starting with the same letter.
@MainActor
final class ImportMnemonicGridTests: TestCase {
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

	/// Ensure that an incorrect input by user which auto completes the word
	/// "add" into "addict" since user addicentally typed "i", results in "add"
	/// after user erases "i" and focuses next TextField.
	func test_addi_erase_results_in_add_not_addict() async throws {
		let mnemonic = try Mnemonic(phrase: "add addict address pen penalty pencil act action actor actress zoo wreck", language: .english)
		let wordsBIP39 = mnemonic.words
		let testClock = TestClock()
		let store = TestStore(
			initialState: ImportMnemonicGrid.State(
				count: .twelve,
				isWordCountFixed: false
			)
		) {
			ImportMnemonicGrid()
		} withDependencies: {
			$0.continuousClock = testClock
			$0.mnemonicClient = .liveValue
		}

		store.exhaustivity = .off

		for (index, wordBIP39) in wordsBIP39.enumerated() {
			let word4Letters = String(wordBIP39.word.prefix(4))

			if wordBIP39.word == "add" {
				await store.send(
					.child(
						.word(
							index,
							.view(.wordChanged(input: "addi")) // => addict, incorrect, erasing..
						)
					)
				)
				await store.send(
					.child(
						.word(
							index,
							.view(.wordChanged(input: "add")) // corrected to "add"
						)
					)
				)
			} else {
				await store.send(
					.child(
						.word(
							index,
							.view(.wordChanged(input: word4Letters))
						)
					)
				)
			}
			await store.send(
				.child(
					.word(
						index,
						.delegate(.lostFocus(displayText: word4Letters))
					)
				)
			)
		}
		XCTAssertEqual(store.state.mnemonic, mnemonic)
	}
}

extension ImportMnemonicGridTests {
	private func doTest(mnemonic phrase: String) async throws {
		let mnemonic = try Mnemonic(phrase: phrase, language: .english)
		let wordsBIP39 = mnemonic.words
		let wordStrings = wordsBIP39.map(\.word)
		XCTAssertEqual(phrase, wordStrings.joined(separator: " "))
		let testClock = TestClock()
		let store = TestStore(
			initialState: ImportMnemonicGrid.State(
				count: mnemonic.wordCount,
				isWordCountFixed: false
			)
		) {
			ImportMnemonicGrid()
		} withDependencies: {
			$0.continuousClock = testClock
			$0.mnemonicClient = .liveValue
		}

		store.exhaustivity = .off

		for (index, wordBIP39) in wordsBIP39.enumerated() {
			let word4Letters = String(wordBIP39.word.prefix(4))
			await store.send(
				.child(
					.word(
						index,
						.view(.wordChanged(input: word4Letters))
					)
				)
			)
			await store.send(
				.child(
					.word(
						index,
						.delegate(.lostFocus(displayText: word4Letters))
					)
				)
			)
		}
		XCTAssertEqual(store.state.mnemonic, mnemonic)
	}
}

private extension ImportMnemonicGrid.State {
	var mnemonic: Mnemonic? {
		let completedWords = words.compactMap(\.completeWord)
		return try? Mnemonic(
			words: completedWords
		)
	}
}
