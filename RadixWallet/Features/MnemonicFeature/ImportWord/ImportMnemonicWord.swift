import ComposableArchitecture
import SwiftUI

// MARK: - ImportMnemonicWord
struct ImportMnemonicWord: Sendable, FeatureReducer {
	struct State: Sendable, Hashable, Identifiable {
		enum Field: Hashable, Sendable {
			case textField
		}

		enum WordValue: Sendable, Hashable {
			case incomplete(
				text: String,
				hasFailedValidation: Bool
			)

			case complete(
				text: String, // might be empty if user pressed candidates button when empty
				word: BIP39Word,
				completion: Completion
			)

			enum Completion: Sendable, Hashable {
				/// We automatically completed the word, since it was unambigiously identified as a BIP39 word.
				case auto(match: BIP39LookupResult.Known.UnambiguousMatch)

				/// User explicitly chose the word from a list of candidates.
				case user
			}

			var isComplete: Bool {
				switch self {
				case .complete: true
				case .incomplete: false
				}
			}

			var hasFailedValidation: Bool {
				guard case let .incomplete(_, hasFailedValidation) = self else {
					return false
				}
				return hasFailedValidation
			}

			var text: String {
				switch self {
				case let .complete(_, word, _):
					word.word
				case let .incomplete(text, _):
					text
				}
			}

			var input: String {
				switch self {
				case let .complete(text, _, _):
					text
				case let .incomplete(text, _):
					text
				}
			}
		}

		struct AutocompletionCandidates: Sendable, Hashable {
			let input: NonEmptyString
			let candidates: NonEmpty<OrderedSet<BIP39Word>>
		}

		typealias ID = Int
		let id: ID
		var value: WordValue

		var autocompletionCandidates: AutocompletionCandidates? = nil
		var focusedField: Field? = nil

		init(
			id: ID,
			value: WordValue = .incomplete(text: "", hasFailedValidation: false)
		) {
			self.id = id
			self.value = value
		}

		var isComplete: Bool {
			value.isComplete
		}

		var completeWord: BIP39Word? {
			guard case let .complete(_, word, _) = value else {
				return nil
			}
			return word
		}

		mutating func focus() {
			self.focusedField = .textField
		}

		mutating func resignFocus() {
			self.focusedField = nil
		}
	}

	enum ViewAction: Sendable, Hashable {
		case wordChanged(input: String)
		case userSelectedCandidate(BIP39Word)
		case focusChanged(State.Field?)
		case onSubmit
	}

	enum DelegateAction: Sendable, Hashable {
		case lookupWord(input: String)
		case lostFocus(displayText: String)
		case userSelectedCandidate(BIP39Word, fromPartial: String)
		case didSubmit
	}

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .wordChanged(input):
			// FIXME: - No autocompletion, so this is disabled for now.
//			switch state.value {
//			case let .complete(text, _, completion: .auto(match: .startsWith)):
//				guard input != text else {
//					// This is an unfortunate edge case we need to handle (perhaps can be solved in view layer?),
//					// if text was "com" and we type "f" the word gets autocompleted into "comfort", however,
//					// SwiftUI will **immediately** afterwards emit another "comf" event. Which we wanna prevent.
//					return .none
//				}
//			default: break
//			}

//			guard input.count >= state.value.text.count else {
//				switch state.value {
//				case let .incomplete(text: _, hasFailedValidation) where hasFailedValidation:
//					// allow lookup if current word is invalid
//					return .send(.delegate(.lookupWord(input: input)))
//				default:
//					// We don't perform lookup when we decrease character count if the
//					// state is not currently "incomplete(_, hasFailedValidation: true)
//					state.value = .incomplete(text: input, hasFailedValidation: false)
//					return .none
//				}
//			}

			return .send(.delegate(.lookupWord(input: input)))

		case let .userSelectedCandidate(candidate):
			return .send(.delegate(.userSelectedCandidate(
				candidate,
				fromPartial: state.value.text
			)))

		case let .focusChanged(field):
			state.focusedField = field
			return .none

		case .onSubmit:
			return .send(.delegate(.didSubmit))
		}
	}
}
