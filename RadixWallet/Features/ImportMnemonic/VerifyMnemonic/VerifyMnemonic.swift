import ComposableArchitecture
import SwiftUI

// MARK: - VerifyMnemonic
public struct VerifyMnemonic: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public static let numberOfRandomWordsToConfirm = 3

		public let mnemonic: Mnemonic
		public let wordsToConfirm: NonEmpty<IdentifiedArrayOf<OffsetIdentified<BIP39Word>>>
		public var enteredWords: IdentifiedArrayOf<OffsetIdentified<String>>
		public var focusedField: Int?
		public var invalidMnemonic: Bool = false

		public init(mnemonic: Mnemonic) {
//			self.mnemonic = mnemonic
//
//			let identifiedWords = mnemonic.words.identifiablyEnumerated()
//			let checksumWord = identifiedWords.last!
//			var randomWords = identifiedWords
//				.dropLast() // without checksum word
//				.shuffled() // randomize
//				.prefix(Self.numberOfRandomWordsToConfirm) // take the required number of words
//				.sorted { $0.offset < $1.offset } // sort after shuffling
//			randomWords.append(checksumWord)
//
//			self.wordsToConfirm = .init(randomWords)!
//			self.enteredWords = wordsToConfirm.rawValue.map {
//				OffsetIdentified(offset: $0.offset, element: "")
//			}.asIdentified()
//
//			self.focusedField = wordsToConfirm.first?.offset
			sargonProfileFinishMigrateAtEndOfStage1()
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case wordChanged(OffsetIdentified<String>)
		case wordSubmitted
		case textFieldFocused(Int?)
		case confirmSeedPhraseButtonTapped
		#if DEBUG
		case debugCheat
		#endif
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
//			let mnemonicMatches = zip(
//				state.enteredWords.elements,
//				state.wordsToConfirm.rawValue.elements
//			).reduce(true) { partialResult, words in
//				partialResult && words.0.element == words.1.element.word.rawValue
//			}
//
//			if mnemonicMatches {
//				overlayWindowClient.scheduleHUD(.succeeded)
//				return .send(.delegate(.mnemonicVerified))
//			} else {
//				state.invalidMnemonic = true
//				return .none
//			}
			sargonProfileFinishMigrateAtEndOfStage1()

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
