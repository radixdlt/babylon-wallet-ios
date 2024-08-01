import ComposableArchitecture
import SwiftUI

// MARK: - ImportMnemonicWord
public struct ImportMnemonicWord: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public enum Field: Hashable, Sendable {
			case textField
		}

		public enum WordValue: Sendable, Hashable {
			case incomplete(
				text: String,
				hasFailedValidation: Bool
			)

			case complete(
				text: String, // might be empty if user pressed candidates button when empty
				word: BIP39Word,
				completion: Completion
			)

			public enum Completion: Sendable, Hashable {
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

		public struct AutocompletionCandidates: Sendable, Hashable {
			public let input: NonEmptyString
			public let candidates: NonEmpty<OrderedSet<BIP39Word>>
		}

		public typealias ID = Int
		public let id: ID
		public var value: WordValue
		public let isReadonlyMode: Bool

		public var autocompletionCandidates: AutocompletionCandidates? = nil
		public var focusedField: Field? = nil

		public init(
			id: ID,
			value: WordValue = .incomplete(text: "", hasFailedValidation: false),
			isReadonlyMode: Bool
		) {
			self.id = id
			self.value = value
			self.isReadonlyMode = isReadonlyMode
		}

		public var isComplete: Bool {
			value.isComplete
		}

		public var completeWord: BIP39Word? {
			guard case let .complete(_, word, _) = value else {
				return nil
			}
			return word
		}

		public mutating func focus() {
			self.focusedField = .textField
		}

		public mutating func resignFocus() {
			self.focusedField = nil
		}
	}

	public enum ViewAction: Sendable, Hashable {
		case wordChanged(input: String)
		case userSelectedCandidate(BIP39Word)
		case textFieldFocused(State.Field?)
	}

	public enum DelegateAction: Sendable, Hashable {
		case lookupWord(input: String)
		case lostFocus(displayText: String)
		case userSelectedCandidate(BIP39Word, fromPartial: String)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .wordChanged(input):
			guard !state.isReadonlyMode else { return .none }
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

		case let .textFieldFocused(field):
			state.focusedField = field
			return field == nil ? .send(.delegate(.lostFocus(displayText: state.value.text))) : .none
		}
	}
}
