import ComposableArchitecture
import SwiftUI

// MARK: - DisplayMnemonic
public struct VerifyMnemonic: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public static let numberOfWordsToConfirm = 3

		public let mnemonic: Mnemonic
		public let wordsToConfirm: NonEmpty<IdentifiedArrayOf<OffsetIdentified<Mnemonic.Word>>>
		public var enteredWords: IdentifiedArrayOf<OffsetIdentified<String>>
		public var focusedField: Int?
		public var invalidMnemonic: Bool = false

		public init(mnemonic: Mnemonic) {
			self.mnemonic = mnemonic

			let identifiedWords = mnemonic.words.identifiablyEnumerated()
			let checksumWord = identifiedWords.last!
			let randomWords = identifiedWords
				.dropLast() // without checksum word
				.shuffled() // randomize
				.prefix(Self.numberOfWordsToConfirm) // take the required number of words
				.sorted { $0.offset < $1.offset } // sort after shuffling

			self.wordsToConfirm = .init(randomWords + [checksumWord])!
			self.enteredWords = wordsToConfirm.rawValue.map {
				OffsetIdentified(offset: $0.offset, element: "")
			}.asIdentifiable()
			self.focusedField = wordsToConfirm.first?.offset
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case wordChanged(OffsetIdentified<String>)
		case wordSubmitted
		case textFieldFocused(Int?)
		case confirmSeedPhraseButtonTapped
		case scrollToPosition
	}

	public enum DelegateAction: Sendable, Equatable {
		case mnemonicVerified
	}

	@Dependency(\.overlayWindowClient) var overlayWindowClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .wordChanged(identifiedWord):
			// reset the invalidMnemonic state
			state.invalidMnemonic = false
			state.enteredWords.updateOrAppend(identifiedWord)
			return .none
		case let .textFieldFocused(focus):
			// Don't set focus to nil if it will be changed to another field
			if focus == nil {
				let didEnterAllWords = state.enteredWords.reduce(true) { partialResult, word in
					partialResult && !word.element.isEmpty
				}

				if didEnterAllWords {
					state.focusedField = nil
				}
				return .none
			}
			state.focusedField = focus
			return .none

		case .wordSubmitted:
			let nextWord = state.enteredWords.first { word in
				word.element.isEmpty
			}
			state.focusedField = nextWord?.offset
			return .none

		case .confirmSeedPhraseButtonTapped:
			let mnemonicMatches = zip(
				state.enteredWords.elements,
				state.wordsToConfirm.rawValue.elements
			).reduce(true) { partialResult, words in
				partialResult && words.0.element == words.1.element.word.rawValue
			}

			if mnemonicMatches {
				overlayWindowClient.scheduleHUD(.succeeded)
				return .send(.delegate(.mnemonicVerified))
			} else {
				state.invalidMnemonic = true
				return .none
			}
		case .scrollToPosition:
			return .none
		}
	}
}
