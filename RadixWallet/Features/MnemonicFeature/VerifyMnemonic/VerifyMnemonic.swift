import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - VerifyMnemonic
struct VerifyMnemonic: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		static let numberOfRandomWordsToConfirm = 3

		let mnemonic: Mnemonic
		let wordsToConfirm: NonEmpty<IdentifiedArrayOf<OffsetIdentified<BIP39Word>>>
		var enteredWords: IdentifiedArrayOf<OffsetIdentified<String>>
		var focusedField: Int?
		var invalidMnemonic: Bool = false

		init(mnemonic: Mnemonic) {
			self.mnemonic = mnemonic

			let identifiedWords = mnemonic.words.identifiablyEnumerated()
			let checksumWord = identifiedWords.last!
			var randomWords = identifiedWords
				.dropLast() // without checksum word
				.shuffled() // randomize
				.prefix(Self.numberOfRandomWordsToConfirm) // take the required number of words
				.sorted { $0.offset < $1.offset } // sort after shuffling
			randomWords.append(checksumWord)

			self.wordsToConfirm = .init(randomWords)!
			self.enteredWords = wordsToConfirm.rawValue.map {
				OffsetIdentified(offset: $0.offset, element: "")
			}.asIdentified()

			self.focusedField = wordsToConfirm.first?.offset
		}
	}

	enum ViewAction: Sendable, Equatable {
		case wordChanged(OffsetIdentified<String>)
		case wordSubmitted
		case textFieldFocused(Int?)
		case confirmSeedPhraseButtonTapped
		#if DEBUG
		case debugCheat
		#endif
	}

	enum DelegateAction: Sendable, Equatable {
		case mnemonicVerified
	}

	@Dependency(\.overlayWindowClient) var overlayWindowClient

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .wordChanged(identifiedWord):
			// reset the invalidMnemonic state
			state.invalidMnemonic = false
			state.enteredWords.updateOrAppend(identifiedWord)
			return .none

		case let .textFieldFocused(focus):
			let done = state.enteredWords.allSatisfy { !$0.isEmpty }

			if let focus {
				state.focusedField = focus
			} else if done {
				state.focusedField = nil
			}

			return .none

		case .wordSubmitted:
			let nextWord = state.enteredWords.first { word in
				word.isEmpty
			}
			state.focusedField = nextWord?.offset
			return .none

		case .confirmSeedPhraseButtonTapped:
			let mnemonicMatches = zip(
				state.enteredWords.elements,
				state.wordsToConfirm.rawValue.elements
			).reduce(true) { partialResult, words in
				partialResult && words.0.element == words.1.element.word
			}

			if mnemonicMatches {
				overlayWindowClient.scheduleHUD(.succeeded)
				return .send(.delegate(.mnemonicVerified))
			} else {
				state.invalidMnemonic = true
				return .none
			}

		#if DEBUG
		case .debugCheat:
			overlayWindowClient.scheduleHUD(.succeeded)
			return .send(.delegate(.mnemonicVerified))
		#endif
		}
	}
}

private extension OverlayWindowClient.Item.HUD {
	static let succeeded = Self(text: L10n.ImportMnemonic.verificationSuccess)
}
